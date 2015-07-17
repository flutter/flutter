// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/nss_util.h"
#include "crypto/nss_util_internal.h"

#include <nss.h>
#include <pk11pub.h>
#include <plarena.h>
#include <prerror.h>
#include <prinit.h>
#include <prtime.h>
#include <secmod.h>

#if defined(OS_OPENBSD)
#include <sys/mount.h>
#include <sys/param.h>
#endif

#if defined(OS_CHROMEOS)
#include <dlfcn.h>
#endif

#include <map>
#include <vector>

#include "base/base_paths.h"
#include "base/bind.h"
#include "base/cpu.h"
#include "base/debug/alias.h"
#include "base/debug/stack_trace.h"
#include "base/environment.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/native_library.h"
#include "base/path_service.h"
#include "base/stl_util.h"
#include "base/strings/stringprintf.h"
#include "base/threading/thread_checker.h"
#include "base/threading/thread_restrictions.h"
#include "base/threading/worker_pool.h"
#include "build/build_config.h"

// USE_NSS_CERTS means NSS is used for certificates and platform integration.
// This requires additional support to manage the platform certificate and key
// stores.
#if defined(USE_NSS_CERTS)
#include "base/synchronization/lock.h"
#include "crypto/nss_crypto_module_delegate.h"
#endif  // defined(USE_NSS_CERTS)

namespace crypto {

namespace {

#if defined(OS_CHROMEOS)
const char kUserNSSDatabaseName[] = "UserNSSDB";

// Constants for loading the Chrome OS TPM-backed PKCS #11 library.
const char kChapsModuleName[] = "Chaps";
const char kChapsPath[] = "libchaps.so";

// Fake certificate authority database used for testing.
static const base::FilePath::CharType kReadOnlyCertDB[] =
    FILE_PATH_LITERAL("/etc/fake_root_ca/nssdb");
#endif  // defined(OS_CHROMEOS)

std::string GetNSSErrorMessage() {
  std::string result;
  if (PR_GetErrorTextLength()) {
    scoped_ptr<char[]> error_text(new char[PR_GetErrorTextLength() + 1]);
    PRInt32 copied = PR_GetErrorText(error_text.get());
    result = std::string(error_text.get(), copied);
  } else {
    result = base::StringPrintf("NSS error code: %d", PR_GetError());
  }
  return result;
}

#if defined(USE_NSS_CERTS)
#if !defined(OS_CHROMEOS)
base::FilePath GetDefaultConfigDirectory() {
  base::FilePath dir;
  PathService::Get(base::DIR_HOME, &dir);
  if (dir.empty()) {
    LOG(ERROR) << "Failed to get home directory.";
    return dir;
  }
  dir = dir.AppendASCII(".pki").AppendASCII("nssdb");
  if (!base::CreateDirectory(dir)) {
    LOG(ERROR) << "Failed to create " << dir.value() << " directory.";
    dir.clear();
  }
  DVLOG(2) << "DefaultConfigDirectory: " << dir.value();
  return dir;
}
#endif  // !defined(IS_CHROMEOS)

// On non-Chrome OS platforms, return the default config directory. On Chrome OS
// test images, return a read-only directory with fake root CA certs (which are
// used by the local Google Accounts server mock we use when testing our login
// code). On Chrome OS non-test images (where the read-only directory doesn't
// exist), return an empty path.
base::FilePath GetInitialConfigDirectory() {
#if defined(OS_CHROMEOS)
  base::FilePath database_dir = base::FilePath(kReadOnlyCertDB);
  if (!base::PathExists(database_dir))
    database_dir.clear();
  return database_dir;
#else
  return GetDefaultConfigDirectory();
#endif  // defined(OS_CHROMEOS)
}

// This callback for NSS forwards all requests to a caller-specified
// CryptoModuleBlockingPasswordDelegate object.
char* PKCS11PasswordFunc(PK11SlotInfo* slot, PRBool retry, void* arg) {
  crypto::CryptoModuleBlockingPasswordDelegate* delegate =
      reinterpret_cast<crypto::CryptoModuleBlockingPasswordDelegate*>(arg);
  if (delegate) {
    bool cancelled = false;
    std::string password = delegate->RequestPassword(PK11_GetTokenName(slot),
                                                     retry != PR_FALSE,
                                                     &cancelled);
    if (cancelled)
      return NULL;
    char* result = PORT_Strdup(password.c_str());
    password.replace(0, password.size(), password.size(), 0);
    return result;
  }
  DLOG(ERROR) << "PK11 password requested with NULL arg";
  return NULL;
}

// NSS creates a local cache of the sqlite database if it detects that the
// filesystem the database is on is much slower than the local disk.  The
// detection doesn't work with the latest versions of sqlite, such as 3.6.22
// (NSS bug https://bugzilla.mozilla.org/show_bug.cgi?id=578561).  So we set
// the NSS environment variable NSS_SDB_USE_CACHE to "yes" to override NSS's
// detection when database_dir is on NFS.  See http://crbug.com/48585.
//
// TODO(wtc): port this function to other USE_NSS_CERTS platforms.  It is
// defined only for OS_LINUX and OS_OPENBSD simply because the statfs structure
// is OS-specific.
//
// Because this function sets an environment variable it must be run before we
// go multi-threaded.
void UseLocalCacheOfNSSDatabaseIfNFS(const base::FilePath& database_dir) {
  bool db_on_nfs = false;
#if defined(OS_LINUX)
  base::FileSystemType fs_type = base::FILE_SYSTEM_UNKNOWN;
  if (base::GetFileSystemType(database_dir, &fs_type))
    db_on_nfs = (fs_type == base::FILE_SYSTEM_NFS);
#elif defined(OS_OPENBSD)
  struct statfs buf;
  if (statfs(database_dir.value().c_str(), &buf) == 0)
    db_on_nfs = (strcmp(buf.f_fstypename, MOUNT_NFS) == 0);
#else
  NOTIMPLEMENTED();
#endif

  if (db_on_nfs) {
    scoped_ptr<base::Environment> env(base::Environment::Create());
    static const char kUseCacheEnvVar[] = "NSS_SDB_USE_CACHE";
    if (!env->HasVar(kUseCacheEnvVar))
      env->SetVar(kUseCacheEnvVar, "yes");
  }
}

#endif  // defined(USE_NSS_CERTS)

// A singleton to initialize/deinitialize NSPR.
// Separate from the NSS singleton because we initialize NSPR on the UI thread.
// Now that we're leaking the singleton, we could merge back with the NSS
// singleton.
class NSPRInitSingleton {
 private:
  friend struct base::DefaultLazyInstanceTraits<NSPRInitSingleton>;

  NSPRInitSingleton() {
    PR_Init(PR_USER_THREAD, PR_PRIORITY_NORMAL, 0);
  }

  // NOTE(willchan): We don't actually execute this code since we leak NSS to
  // prevent non-joinable threads from using NSS after it's already been shut
  // down.
  ~NSPRInitSingleton() {
    PL_ArenaFinish();
    PRStatus prstatus = PR_Cleanup();
    if (prstatus != PR_SUCCESS)
      LOG(ERROR) << "PR_Cleanup failed; was NSPR initialized on wrong thread?";
  }
};

base::LazyInstance<NSPRInitSingleton>::Leaky
    g_nspr_singleton = LAZY_INSTANCE_INITIALIZER;

// Force a crash with error info on NSS_NoDB_Init failure.
void CrashOnNSSInitFailure() {
  int nss_error = PR_GetError();
  int os_error = PR_GetOSError();
  base::debug::Alias(&nss_error);
  base::debug::Alias(&os_error);
  LOG(ERROR) << "Error initializing NSS without a persistent database: "
             << GetNSSErrorMessage();
  LOG(FATAL) << "nss_error=" << nss_error << ", os_error=" << os_error;
}

#if defined(OS_CHROMEOS)
class ChromeOSUserData {
 public:
  explicit ChromeOSUserData(ScopedPK11Slot public_slot)
      : public_slot_(public_slot.Pass()),
        private_slot_initialization_started_(false) {}
  ~ChromeOSUserData() {
    if (public_slot_) {
      SECStatus status = SECMOD_CloseUserDB(public_slot_.get());
      if (status != SECSuccess)
        PLOG(ERROR) << "SECMOD_CloseUserDB failed: " << PORT_GetError();
    }
  }

  ScopedPK11Slot GetPublicSlot() {
    return ScopedPK11Slot(
        public_slot_ ? PK11_ReferenceSlot(public_slot_.get()) : NULL);
  }

  ScopedPK11Slot GetPrivateSlot(
      const base::Callback<void(ScopedPK11Slot)>& callback) {
    if (private_slot_)
      return ScopedPK11Slot(PK11_ReferenceSlot(private_slot_.get()));
    if (!callback.is_null())
      tpm_ready_callback_list_.push_back(callback);
    return ScopedPK11Slot();
  }

  void SetPrivateSlot(ScopedPK11Slot private_slot) {
    DCHECK(!private_slot_);
    private_slot_ = private_slot.Pass();

    SlotReadyCallbackList callback_list;
    callback_list.swap(tpm_ready_callback_list_);
    for (SlotReadyCallbackList::iterator i = callback_list.begin();
         i != callback_list.end();
         ++i) {
      (*i).Run(ScopedPK11Slot(PK11_ReferenceSlot(private_slot_.get())));
    }
  }

  bool private_slot_initialization_started() const {
      return private_slot_initialization_started_;
  }

  void set_private_slot_initialization_started() {
      private_slot_initialization_started_ = true;
  }

 private:
  ScopedPK11Slot public_slot_;
  ScopedPK11Slot private_slot_;

  bool private_slot_initialization_started_;

  typedef std::vector<base::Callback<void(ScopedPK11Slot)> >
      SlotReadyCallbackList;
  SlotReadyCallbackList tpm_ready_callback_list_;
};

class ScopedChapsLoadFixup {
  public:
    ScopedChapsLoadFixup();
    ~ScopedChapsLoadFixup();

  private:
#if defined(COMPONENT_BUILD)
    void *chaps_handle_;
#endif
};

#if defined(COMPONENT_BUILD)

ScopedChapsLoadFixup::ScopedChapsLoadFixup() {
  // HACK: libchaps links the system protobuf and there are symbol conflicts
  // with the bundled copy. Load chaps with RTLD_DEEPBIND to workaround.
  chaps_handle_ = dlopen(kChapsPath, RTLD_LOCAL | RTLD_NOW | RTLD_DEEPBIND);
}

ScopedChapsLoadFixup::~ScopedChapsLoadFixup() {
  // LoadModule() will have taken a 2nd reference.
  if (chaps_handle_)
    dlclose(chaps_handle_);
}

#else

ScopedChapsLoadFixup::ScopedChapsLoadFixup() {}
ScopedChapsLoadFixup::~ScopedChapsLoadFixup() {}

#endif  // defined(COMPONENT_BUILD)
#endif  // defined(OS_CHROMEOS)

class NSSInitSingleton {
 public:
#if defined(OS_CHROMEOS)
  // Used with PostTaskAndReply to pass handles to worker thread and back.
  struct TPMModuleAndSlot {
    explicit TPMModuleAndSlot(SECMODModule* init_chaps_module)
        : chaps_module(init_chaps_module) {}
    SECMODModule* chaps_module;
    crypto::ScopedPK11Slot tpm_slot;
  };

  ScopedPK11Slot OpenPersistentNSSDBForPath(const std::string& db_name,
                                            const base::FilePath& path) {
    DCHECK(thread_checker_.CalledOnValidThread());
    // NSS is allowed to do IO on the current thread since dispatching
    // to a dedicated thread would still have the affect of blocking
    // the current thread, due to NSS's internal locking requirements
    base::ThreadRestrictions::ScopedAllowIO allow_io;

    base::FilePath nssdb_path = path.AppendASCII(".pki").AppendASCII("nssdb");
    if (!base::CreateDirectory(nssdb_path)) {
      LOG(ERROR) << "Failed to create " << nssdb_path.value() << " directory.";
      return ScopedPK11Slot();
    }
    return OpenSoftwareNSSDB(nssdb_path, db_name);
  }

  void EnableTPMTokenForNSS() {
    DCHECK(thread_checker_.CalledOnValidThread());

    // If this gets set, then we'll use the TPM for certs with
    // private keys, otherwise we'll fall back to the software
    // implementation.
    tpm_token_enabled_for_nss_ = true;
  }

  bool IsTPMTokenEnabledForNSS() {
    DCHECK(thread_checker_.CalledOnValidThread());
    return tpm_token_enabled_for_nss_;
  }

  void InitializeTPMTokenAndSystemSlot(
      int system_slot_id,
      const base::Callback<void(bool)>& callback) {
    DCHECK(thread_checker_.CalledOnValidThread());
    // Should not be called while there is already an initialization in
    // progress.
    DCHECK(!initializing_tpm_token_);
    // If EnableTPMTokenForNSS hasn't been called, return false.
    if (!tpm_token_enabled_for_nss_) {
      base::MessageLoop::current()->PostTask(FROM_HERE,
                                             base::Bind(callback, false));
      return;
    }

    // If everything is already initialized, then return true.
    // Note that only |tpm_slot_| is checked, since |chaps_module_| could be
    // NULL in tests while |tpm_slot_| has been set to the test DB.
    if (tpm_slot_) {
      base::MessageLoop::current()->PostTask(FROM_HERE,
                                             base::Bind(callback, true));
      return;
    }

    // Note that a reference is not taken to chaps_module_. This is safe since
    // NSSInitSingleton is Leaky, so the reference it holds is never released.
    scoped_ptr<TPMModuleAndSlot> tpm_args(new TPMModuleAndSlot(chaps_module_));
    TPMModuleAndSlot* tpm_args_ptr = tpm_args.get();
    if (base::WorkerPool::PostTaskAndReply(
            FROM_HERE,
            base::Bind(&NSSInitSingleton::InitializeTPMTokenOnWorkerThread,
                       system_slot_id,
                       tpm_args_ptr),
            base::Bind(&NSSInitSingleton::OnInitializedTPMTokenAndSystemSlot,
                       base::Unretained(this),  // NSSInitSingleton is leaky
                       callback,
                       base::Passed(&tpm_args)),
            true /* task_is_slow */
            )) {
      initializing_tpm_token_ = true;
    } else {
      base::MessageLoop::current()->PostTask(FROM_HERE,
                                             base::Bind(callback, false));
    }
  }

  static void InitializeTPMTokenOnWorkerThread(CK_SLOT_ID token_slot_id,
                                               TPMModuleAndSlot* tpm_args) {
    // This tries to load the Chaps module so NSS can talk to the hardware
    // TPM.
    if (!tpm_args->chaps_module) {
      ScopedChapsLoadFixup chaps_loader;

      DVLOG(3) << "Loading chaps...";
      tpm_args->chaps_module = LoadModule(
          kChapsModuleName,
          kChapsPath,
          // For more details on these parameters, see:
          // https://developer.mozilla.org/en/PKCS11_Module_Specs
          // slotFlags=[PublicCerts] -- Certificates and public keys can be
          //   read from this slot without requiring a call to C_Login.
          // askpw=only -- Only authenticate to the token when necessary.
          "NSS=\"slotParams=(0={slotFlags=[PublicCerts] askpw=only})\"");
    }
    if (tpm_args->chaps_module) {
      tpm_args->tpm_slot =
          GetTPMSlotForIdOnWorkerThread(tpm_args->chaps_module, token_slot_id);
    }
  }

  void OnInitializedTPMTokenAndSystemSlot(
      const base::Callback<void(bool)>& callback,
      scoped_ptr<TPMModuleAndSlot> tpm_args) {
    DCHECK(thread_checker_.CalledOnValidThread());
    DVLOG(2) << "Loaded chaps: " << !!tpm_args->chaps_module
             << ", got tpm slot: " << !!tpm_args->tpm_slot;

    chaps_module_ = tpm_args->chaps_module;
    tpm_slot_ = tpm_args->tpm_slot.Pass();
    if (!chaps_module_ && test_system_slot_) {
      // chromeos_unittests try to test the TPM initialization process. If we
      // have a test DB open, pretend that it is the TPM slot.
      tpm_slot_.reset(PK11_ReferenceSlot(test_system_slot_.get()));
    }
    initializing_tpm_token_ = false;

    if (tpm_slot_)
      RunAndClearTPMReadyCallbackList();

    callback.Run(!!tpm_slot_);
  }

  void RunAndClearTPMReadyCallbackList() {
    TPMReadyCallbackList callback_list;
    callback_list.swap(tpm_ready_callback_list_);
    for (TPMReadyCallbackList::iterator i = callback_list.begin();
         i != callback_list.end();
         ++i) {
      i->Run();
    }
  }

  bool IsTPMTokenReady(const base::Closure& callback) {
    if (!callback.is_null()) {
      // Cannot DCHECK in the general case yet, but since the callback is
      // a new addition to the API, DCHECK to make sure at least the new uses
      // don't regress.
      DCHECK(thread_checker_.CalledOnValidThread());
    } else if (!thread_checker_.CalledOnValidThread()) {
      // TODO(mattm): Change to DCHECK when callers have been fixed.
      DVLOG(1) << "Called on wrong thread.\n"
               << base::debug::StackTrace().ToString();
    }

    if (tpm_slot_)
      return true;

    if (!callback.is_null())
      tpm_ready_callback_list_.push_back(callback);

    return false;
  }

  // Note that CK_SLOT_ID is an unsigned long, but cryptohome gives us the slot
  // id as an int. This should be safe since this is only used with chaps, which
  // we also control.
  static crypto::ScopedPK11Slot GetTPMSlotForIdOnWorkerThread(
      SECMODModule* chaps_module,
      CK_SLOT_ID slot_id) {
    DCHECK(chaps_module);

    DVLOG(3) << "Poking chaps module.";
    SECStatus rv = SECMOD_UpdateSlotList(chaps_module);
    if (rv != SECSuccess)
      PLOG(ERROR) << "SECMOD_UpdateSlotList failed: " << PORT_GetError();

    PK11SlotInfo* slot = SECMOD_LookupSlot(chaps_module->moduleID, slot_id);
    if (!slot)
      LOG(ERROR) << "TPM slot " << slot_id << " not found.";
    return crypto::ScopedPK11Slot(slot);
  }

  bool InitializeNSSForChromeOSUser(const std::string& username_hash,
                                    const base::FilePath& path) {
    DCHECK(thread_checker_.CalledOnValidThread());
    if (chromeos_user_map_.find(username_hash) != chromeos_user_map_.end()) {
      // This user already exists in our mapping.
      DVLOG(2) << username_hash << " already initialized.";
      return false;
    }

    DVLOG(2) << "Opening NSS DB " << path.value();
    std::string db_name = base::StringPrintf(
        "%s %s", kUserNSSDatabaseName, username_hash.c_str());
    ScopedPK11Slot public_slot(OpenPersistentNSSDBForPath(db_name, path));
    chromeos_user_map_[username_hash] =
        new ChromeOSUserData(public_slot.Pass());
    return true;
  }

  bool ShouldInitializeTPMForChromeOSUser(const std::string& username_hash) {
    DCHECK(thread_checker_.CalledOnValidThread());
    DCHECK(chromeos_user_map_.find(username_hash) != chromeos_user_map_.end());

    return !chromeos_user_map_[username_hash]
                ->private_slot_initialization_started();
  }

  void WillInitializeTPMForChromeOSUser(const std::string& username_hash) {
    DCHECK(thread_checker_.CalledOnValidThread());
    DCHECK(chromeos_user_map_.find(username_hash) != chromeos_user_map_.end());

    chromeos_user_map_[username_hash]
        ->set_private_slot_initialization_started();
  }

  void InitializeTPMForChromeOSUser(const std::string& username_hash,
                                    CK_SLOT_ID slot_id) {
    DCHECK(thread_checker_.CalledOnValidThread());
    DCHECK(chromeos_user_map_.find(username_hash) != chromeos_user_map_.end());
    DCHECK(chromeos_user_map_[username_hash]->
               private_slot_initialization_started());

    if (!chaps_module_)
      return;

    // Note that a reference is not taken to chaps_module_. This is safe since
    // NSSInitSingleton is Leaky, so the reference it holds is never released.
    scoped_ptr<TPMModuleAndSlot> tpm_args(new TPMModuleAndSlot(chaps_module_));
    TPMModuleAndSlot* tpm_args_ptr = tpm_args.get();
    base::WorkerPool::PostTaskAndReply(
        FROM_HERE,
        base::Bind(&NSSInitSingleton::InitializeTPMTokenOnWorkerThread,
                   slot_id,
                   tpm_args_ptr),
        base::Bind(&NSSInitSingleton::OnInitializedTPMForChromeOSUser,
                   base::Unretained(this),  // NSSInitSingleton is leaky
                   username_hash,
                   base::Passed(&tpm_args)),
        true /* task_is_slow */
        );
  }

  void OnInitializedTPMForChromeOSUser(const std::string& username_hash,
                                       scoped_ptr<TPMModuleAndSlot> tpm_args) {
    DCHECK(thread_checker_.CalledOnValidThread());
    DVLOG(2) << "Got tpm slot for " << username_hash << " "
             << !!tpm_args->tpm_slot;
    chromeos_user_map_[username_hash]->SetPrivateSlot(
        tpm_args->tpm_slot.Pass());
  }

  void InitializePrivateSoftwareSlotForChromeOSUser(
      const std::string& username_hash) {
    DCHECK(thread_checker_.CalledOnValidThread());
    VLOG(1) << "using software private slot for " << username_hash;
    DCHECK(chromeos_user_map_.find(username_hash) != chromeos_user_map_.end());
    DCHECK(chromeos_user_map_[username_hash]->
               private_slot_initialization_started());

    chromeos_user_map_[username_hash]->SetPrivateSlot(
        chromeos_user_map_[username_hash]->GetPublicSlot());
  }

  ScopedPK11Slot GetPublicSlotForChromeOSUser(
      const std::string& username_hash) {
    DCHECK(thread_checker_.CalledOnValidThread());

    if (username_hash.empty()) {
      DVLOG(2) << "empty username_hash";
      return ScopedPK11Slot();
    }

    if (chromeos_user_map_.find(username_hash) == chromeos_user_map_.end()) {
      LOG(ERROR) << username_hash << " not initialized.";
      return ScopedPK11Slot();
    }
    return chromeos_user_map_[username_hash]->GetPublicSlot();
  }

  ScopedPK11Slot GetPrivateSlotForChromeOSUser(
      const std::string& username_hash,
      const base::Callback<void(ScopedPK11Slot)>& callback) {
    DCHECK(thread_checker_.CalledOnValidThread());

    if (username_hash.empty()) {
      DVLOG(2) << "empty username_hash";
      if (!callback.is_null()) {
        base::MessageLoop::current()->PostTask(
            FROM_HERE, base::Bind(callback, base::Passed(ScopedPK11Slot())));
      }
      return ScopedPK11Slot();
    }

    DCHECK(chromeos_user_map_.find(username_hash) != chromeos_user_map_.end());

    return chromeos_user_map_[username_hash]->GetPrivateSlot(callback);
  }

  void CloseChromeOSUserForTesting(const std::string& username_hash) {
    DCHECK(thread_checker_.CalledOnValidThread());
    ChromeOSUserMap::iterator i = chromeos_user_map_.find(username_hash);
    DCHECK(i != chromeos_user_map_.end());
    delete i->second;
    chromeos_user_map_.erase(i);
  }

  void SetSystemKeySlotForTesting(ScopedPK11Slot slot) {
    // Ensure that a previous value of test_system_slot_ is not overwritten.
    // Unsetting, i.e. setting a NULL, however is allowed.
    DCHECK(!slot || !test_system_slot_);
    test_system_slot_ = slot.Pass();
    if (test_system_slot_) {
      tpm_slot_.reset(PK11_ReferenceSlot(test_system_slot_.get()));
      RunAndClearTPMReadyCallbackList();
    } else {
      tpm_slot_.reset();
    }
  }
#endif  // defined(OS_CHROMEOS)

#if !defined(OS_CHROMEOS)
  PK11SlotInfo* GetPersistentNSSKeySlot() {
    // TODO(mattm): Change to DCHECK when callers have been fixed.
    if (!thread_checker_.CalledOnValidThread()) {
      DVLOG(1) << "Called on wrong thread.\n"
               << base::debug::StackTrace().ToString();
    }

    return PK11_GetInternalKeySlot();
  }
#endif

#if defined(OS_CHROMEOS)
  void GetSystemNSSKeySlotCallback(
      const base::Callback<void(ScopedPK11Slot)>& callback) {
    callback.Run(ScopedPK11Slot(PK11_ReferenceSlot(tpm_slot_.get())));
  }

  ScopedPK11Slot GetSystemNSSKeySlot(
      const base::Callback<void(ScopedPK11Slot)>& callback) {
    DCHECK(thread_checker_.CalledOnValidThread());
    // TODO(mattm): chromeos::TPMTokenloader always calls
    // InitializeTPMTokenAndSystemSlot with slot 0.  If the system slot is
    // disabled, tpm_slot_ will be the first user's slot instead. Can that be
    // detected and return NULL instead?

    base::Closure wrapped_callback;
    if (!callback.is_null()) {
      wrapped_callback =
          base::Bind(&NSSInitSingleton::GetSystemNSSKeySlotCallback,
                     base::Unretained(this) /* singleton is leaky */,
                     callback);
    }
    if (IsTPMTokenReady(wrapped_callback))
      return ScopedPK11Slot(PK11_ReferenceSlot(tpm_slot_.get()));
    return ScopedPK11Slot();
  }
#endif

#if defined(USE_NSS_CERTS)
  base::Lock* write_lock() {
    return &write_lock_;
  }
#endif  // defined(USE_NSS_CERTS)

  // This method is used to force NSS to be initialized without a DB.
  // Call this method before NSSInitSingleton() is constructed.
  static void ForceNoDBInit() {
    force_nodb_init_ = true;
  }

 private:
  friend struct base::DefaultLazyInstanceTraits<NSSInitSingleton>;

  NSSInitSingleton()
      : tpm_token_enabled_for_nss_(false),
        initializing_tpm_token_(false),
        chaps_module_(NULL),
        root_(NULL) {
    // It's safe to construct on any thread, since LazyInstance will prevent any
    // other threads from accessing until the constructor is done.
    thread_checker_.DetachFromThread();

    DisableAESNIIfNeeded();

    EnsureNSPRInit();

    // We *must* have NSS >= 3.14.3.
    static_assert(
        (NSS_VMAJOR == 3 && NSS_VMINOR == 14 && NSS_VPATCH >= 3) ||
        (NSS_VMAJOR == 3 && NSS_VMINOR > 14) ||
        (NSS_VMAJOR > 3),
        "nss version check failed");
    // Also check the run-time NSS version.
    // NSS_VersionCheck is a >= check, not strict equality.
    if (!NSS_VersionCheck("3.14.3")) {
      LOG(FATAL) << "NSS_VersionCheck(\"3.14.3\") failed. NSS >= 3.14.3 is "
                    "required. Please upgrade to the latest NSS, and if you "
                    "still get this error, contact your distribution "
                    "maintainer.";
    }

    SECStatus status = SECFailure;
    bool nodb_init = force_nodb_init_;

#if !defined(USE_NSS_CERTS)
    // Use the system certificate store, so initialize NSS without database.
    nodb_init = true;
#endif

    if (nodb_init) {
      status = NSS_NoDB_Init(NULL);
      if (status != SECSuccess) {
        CrashOnNSSInitFailure();
        return;
      }
#if defined(OS_IOS)
      root_ = InitDefaultRootCerts();
#endif  // defined(OS_IOS)
    } else {
#if defined(USE_NSS_CERTS)
      base::FilePath database_dir = GetInitialConfigDirectory();
      if (!database_dir.empty()) {
        // This duplicates the work which should have been done in
        // EarlySetupForNSSInit. However, this function is idempotent so
        // there's no harm done.
        UseLocalCacheOfNSSDatabaseIfNFS(database_dir);

        // Initialize with a persistent database (likely, ~/.pki/nssdb).
        // Use "sql:" which can be shared by multiple processes safely.
        std::string nss_config_dir =
            base::StringPrintf("sql:%s", database_dir.value().c_str());
#if defined(OS_CHROMEOS)
        status = NSS_Init(nss_config_dir.c_str());
#else
        status = NSS_InitReadWrite(nss_config_dir.c_str());
#endif
        if (status != SECSuccess) {
          LOG(ERROR) << "Error initializing NSS with a persistent "
                        "database (" << nss_config_dir
                     << "): " << GetNSSErrorMessage();
        }
      }
      if (status != SECSuccess) {
        VLOG(1) << "Initializing NSS without a persistent database.";
        status = NSS_NoDB_Init(NULL);
        if (status != SECSuccess) {
          CrashOnNSSInitFailure();
          return;
        }
      }

      PK11_SetPasswordFunc(PKCS11PasswordFunc);

      // If we haven't initialized the password for the NSS databases,
      // initialize an empty-string password so that we don't need to
      // log in.
      PK11SlotInfo* slot = PK11_GetInternalKeySlot();
      if (slot) {
        // PK11_InitPin may write to the keyDB, but no other thread can use NSS
        // yet, so we don't need to lock.
        if (PK11_NeedUserInit(slot))
          PK11_InitPin(slot, NULL, NULL);
        PK11_FreeSlot(slot);
      }

      root_ = InitDefaultRootCerts();
#endif  // defined(USE_NSS_CERTS)
    }

    // Disable MD5 certificate signatures. (They are disabled by default in
    // NSS 3.14.)
    NSS_SetAlgorithmPolicy(SEC_OID_MD5, 0, NSS_USE_ALG_IN_CERT_SIGNATURE);
    NSS_SetAlgorithmPolicy(SEC_OID_PKCS1_MD5_WITH_RSA_ENCRYPTION,
                           0, NSS_USE_ALG_IN_CERT_SIGNATURE);
  }

  // NOTE(willchan): We don't actually execute this code since we leak NSS to
  // prevent non-joinable threads from using NSS after it's already been shut
  // down.
  ~NSSInitSingleton() {
#if defined(OS_CHROMEOS)
    STLDeleteValues(&chromeos_user_map_);
#endif
    tpm_slot_.reset();
    if (root_) {
      SECMOD_UnloadUserModule(root_);
      SECMOD_DestroyModule(root_);
      root_ = NULL;
    }
    if (chaps_module_) {
      SECMOD_UnloadUserModule(chaps_module_);
      SECMOD_DestroyModule(chaps_module_);
      chaps_module_ = NULL;
    }

    SECStatus status = NSS_Shutdown();
    if (status != SECSuccess) {
      // We VLOG(1) because this failure is relatively harmless (leaking, but
      // we're shutting down anyway).
      VLOG(1) << "NSS_Shutdown failed; see http://crbug.com/4609";
    }
  }

#if defined(USE_NSS_CERTS) || defined(OS_IOS)
  // Load nss's built-in root certs.
  SECMODModule* InitDefaultRootCerts() {
    SECMODModule* root = LoadModule("Root Certs", "libnssckbi.so", NULL);
    if (root)
      return root;

    // Aw, snap.  Can't find/load root cert shared library.
    // This will make it hard to talk to anybody via https.
    // TODO(mattm): Re-add the NOTREACHED here when crbug.com/310972 is fixed.
    return NULL;
  }

  // Load the given module for this NSS session.
  static SECMODModule* LoadModule(const char* name,
                                  const char* library_path,
                                  const char* params) {
    std::string modparams = base::StringPrintf(
        "name=\"%s\" library=\"%s\" %s",
        name, library_path, params ? params : "");

    // Shouldn't need to const_cast here, but SECMOD doesn't properly
    // declare input string arguments as const.  Bug
    // https://bugzilla.mozilla.org/show_bug.cgi?id=642546 was filed
    // on NSS codebase to address this.
    SECMODModule* module = SECMOD_LoadUserModule(
        const_cast<char*>(modparams.c_str()), NULL, PR_FALSE);
    if (!module) {
      LOG(ERROR) << "Error loading " << name << " module into NSS: "
                 << GetNSSErrorMessage();
      return NULL;
    }
    if (!module->loaded) {
      LOG(ERROR) << "After loading " << name << ", loaded==false: "
                 << GetNSSErrorMessage();
      SECMOD_DestroyModule(module);
      return NULL;
    }
    return module;
  }
#endif

  static void DisableAESNIIfNeeded() {
    if (NSS_VersionCheck("3.15") && !NSS_VersionCheck("3.15.4")) {
      // Some versions of NSS have a bug that causes AVX instructions to be
      // used without testing whether XSAVE is enabled by the operating system.
      // In order to work around this, we disable AES-NI in NSS when we find
      // that |has_avx()| is false (which includes the XSAVE test). See
      // https://bugzilla.mozilla.org/show_bug.cgi?id=940794
      base::CPU cpu;

      if (cpu.has_avx_hardware() && !cpu.has_avx()) {
        scoped_ptr<base::Environment> env(base::Environment::Create());
        env->SetVar("NSS_DISABLE_HW_AES", "1");
      }
    }
  }

  // If this is set to true NSS is forced to be initialized without a DB.
  static bool force_nodb_init_;

  bool tpm_token_enabled_for_nss_;
  bool initializing_tpm_token_;
  typedef std::vector<base::Closure> TPMReadyCallbackList;
  TPMReadyCallbackList tpm_ready_callback_list_;
  SECMODModule* chaps_module_;
  crypto::ScopedPK11Slot tpm_slot_;
  SECMODModule* root_;
#if defined(OS_CHROMEOS)
  typedef std::map<std::string, ChromeOSUserData*> ChromeOSUserMap;
  ChromeOSUserMap chromeos_user_map_;
  ScopedPK11Slot test_system_slot_;
#endif
#if defined(USE_NSS_CERTS)
  // TODO(davidben): When https://bugzilla.mozilla.org/show_bug.cgi?id=564011
  // is fixed, we will no longer need the lock.
  base::Lock write_lock_;
#endif  // defined(USE_NSS_CERTS)

  base::ThreadChecker thread_checker_;
};

// static
bool NSSInitSingleton::force_nodb_init_ = false;

base::LazyInstance<NSSInitSingleton>::Leaky
    g_nss_singleton = LAZY_INSTANCE_INITIALIZER;
}  // namespace

#if defined(USE_NSS_CERTS)
ScopedPK11Slot OpenSoftwareNSSDB(const base::FilePath& path,
                                 const std::string& description) {
  const std::string modspec =
      base::StringPrintf("configDir='sql:%s' tokenDescription='%s'",
                         path.value().c_str(),
                         description.c_str());
  PK11SlotInfo* db_slot = SECMOD_OpenUserDB(modspec.c_str());
  if (db_slot) {
    if (PK11_NeedUserInit(db_slot))
      PK11_InitPin(db_slot, NULL, NULL);
  } else {
    LOG(ERROR) << "Error opening persistent database (" << modspec
               << "): " << GetNSSErrorMessage();
  }
  return ScopedPK11Slot(db_slot);
}

void EarlySetupForNSSInit() {
  base::FilePath database_dir = GetInitialConfigDirectory();
  if (!database_dir.empty())
    UseLocalCacheOfNSSDatabaseIfNFS(database_dir);
}
#endif

void EnsureNSPRInit() {
  g_nspr_singleton.Get();
}

void InitNSSSafely() {
  // We might fork, but we haven't loaded any security modules.
  DisableNSSForkCheck();
  // If we're sandboxed, we shouldn't be able to open user security modules,
  // but it's more correct to tell NSS to not even try.
  // Loading user security modules would have security implications.
  ForceNSSNoDBInit();
  // Initialize NSS.
  EnsureNSSInit();
}

void EnsureNSSInit() {
  // Initializing SSL causes us to do blocking IO.
  // Temporarily allow it until we fix
  //   http://code.google.com/p/chromium/issues/detail?id=59847
  base::ThreadRestrictions::ScopedAllowIO allow_io;
  g_nss_singleton.Get();
}

void ForceNSSNoDBInit() {
  NSSInitSingleton::ForceNoDBInit();
}

void DisableNSSForkCheck() {
  scoped_ptr<base::Environment> env(base::Environment::Create());
  env->SetVar("NSS_STRICT_NOFORK", "DISABLED");
}

void LoadNSSLibraries() {
  // Some NSS libraries are linked dynamically so load them here.
#if defined(USE_NSS_CERTS)
  // Try to search for multiple directories to load the libraries.
  std::vector<base::FilePath> paths;

  // Use relative path to Search PATH for the library files.
  paths.push_back(base::FilePath());

  // For Debian derivatives NSS libraries are located here.
  paths.push_back(base::FilePath("/usr/lib/nss"));

  // Ubuntu 11.10 (Oneiric) and Debian Wheezy place the libraries here.
#if defined(ARCH_CPU_X86_64)
  paths.push_back(base::FilePath("/usr/lib/x86_64-linux-gnu/nss"));
#elif defined(ARCH_CPU_X86)
  paths.push_back(base::FilePath("/usr/lib/i386-linux-gnu/nss"));
#elif defined(ARCH_CPU_ARMEL)
#if defined(__ARM_PCS_VFP)
  paths.push_back(base::FilePath("/usr/lib/arm-linux-gnueabihf/nss"));
#else
  paths.push_back(base::FilePath("/usr/lib/arm-linux-gnueabi/nss"));
#endif  // defined(__ARM_PCS_VFP)
#elif defined(ARCH_CPU_MIPSEL)
  paths.push_back(base::FilePath("/usr/lib/mipsel-linux-gnu/nss"));
#endif  // defined(ARCH_CPU_X86_64)

  // A list of library files to load.
  std::vector<std::string> libs;
  libs.push_back("libsoftokn3.so");
  libs.push_back("libfreebl3.so");

  // For each combination of library file and path, check for existence and
  // then load.
  size_t loaded = 0;
  for (size_t i = 0; i < libs.size(); ++i) {
    for (size_t j = 0; j < paths.size(); ++j) {
      base::FilePath path = paths[j].Append(libs[i]);
      base::NativeLibrary lib = base::LoadNativeLibrary(path, NULL);
      if (lib) {
        ++loaded;
        break;
      }
    }
  }

  if (loaded == libs.size()) {
    VLOG(3) << "NSS libraries loaded.";
  } else {
    LOG(ERROR) << "Failed to load NSS libraries.";
  }
#endif  // defined(USE_NSS_CERTS)
}

bool CheckNSSVersion(const char* version) {
  return !!NSS_VersionCheck(version);
}

#if defined(USE_NSS_CERTS)
base::Lock* GetNSSWriteLock() {
  return g_nss_singleton.Get().write_lock();
}

AutoNSSWriteLock::AutoNSSWriteLock() : lock_(GetNSSWriteLock()) {
  // May be NULL if the lock is not needed in our version of NSS.
  if (lock_)
    lock_->Acquire();
}

AutoNSSWriteLock::~AutoNSSWriteLock() {
  if (lock_) {
    lock_->AssertAcquired();
    lock_->Release();
  }
}

AutoSECMODListReadLock::AutoSECMODListReadLock()
      : lock_(SECMOD_GetDefaultModuleListLock()) {
    SECMOD_GetReadLock(lock_);
  }

AutoSECMODListReadLock::~AutoSECMODListReadLock() {
  SECMOD_ReleaseReadLock(lock_);
}
#endif  // defined(USE_NSS_CERTS)

#if defined(OS_CHROMEOS)
ScopedPK11Slot GetSystemNSSKeySlot(
    const base::Callback<void(ScopedPK11Slot)>& callback) {
  return g_nss_singleton.Get().GetSystemNSSKeySlot(callback);
}

void SetSystemKeySlotForTesting(ScopedPK11Slot slot) {
  g_nss_singleton.Get().SetSystemKeySlotForTesting(slot.Pass());
}

void EnableTPMTokenForNSS() {
  g_nss_singleton.Get().EnableTPMTokenForNSS();
}

bool IsTPMTokenEnabledForNSS() {
  return g_nss_singleton.Get().IsTPMTokenEnabledForNSS();
}

bool IsTPMTokenReady(const base::Closure& callback) {
  return g_nss_singleton.Get().IsTPMTokenReady(callback);
}

void InitializeTPMTokenAndSystemSlot(
    int token_slot_id,
    const base::Callback<void(bool)>& callback) {
  g_nss_singleton.Get().InitializeTPMTokenAndSystemSlot(token_slot_id,
                                                        callback);
}

bool InitializeNSSForChromeOSUser(const std::string& username_hash,
                                  const base::FilePath& path) {
  return g_nss_singleton.Get().InitializeNSSForChromeOSUser(username_hash,
                                                            path);
}

bool ShouldInitializeTPMForChromeOSUser(const std::string& username_hash) {
  return g_nss_singleton.Get().ShouldInitializeTPMForChromeOSUser(
      username_hash);
}

void WillInitializeTPMForChromeOSUser(const std::string& username_hash) {
  g_nss_singleton.Get().WillInitializeTPMForChromeOSUser(username_hash);
}

void InitializeTPMForChromeOSUser(
    const std::string& username_hash,
    CK_SLOT_ID slot_id) {
  g_nss_singleton.Get().InitializeTPMForChromeOSUser(username_hash, slot_id);
}

void InitializePrivateSoftwareSlotForChromeOSUser(
    const std::string& username_hash) {
  g_nss_singleton.Get().InitializePrivateSoftwareSlotForChromeOSUser(
      username_hash);
}

ScopedPK11Slot GetPublicSlotForChromeOSUser(const std::string& username_hash) {
  return g_nss_singleton.Get().GetPublicSlotForChromeOSUser(username_hash);
}

ScopedPK11Slot GetPrivateSlotForChromeOSUser(
    const std::string& username_hash,
    const base::Callback<void(ScopedPK11Slot)>& callback) {
  return g_nss_singleton.Get().GetPrivateSlotForChromeOSUser(username_hash,
                                                             callback);
}

void CloseChromeOSUserForTesting(const std::string& username_hash) {
  g_nss_singleton.Get().CloseChromeOSUserForTesting(username_hash);
}
#endif  // defined(OS_CHROMEOS)

base::Time PRTimeToBaseTime(PRTime prtime) {
  return base::Time::FromInternalValue(
      prtime + base::Time::UnixEpoch().ToInternalValue());
}

PRTime BaseTimeToPRTime(base::Time time) {
  return time.ToInternalValue() - base::Time::UnixEpoch().ToInternalValue();
}

#if !defined(OS_CHROMEOS)
PK11SlotInfo* GetPersistentNSSKeySlot() {
  return g_nss_singleton.Get().GetPersistentNSSKeySlot();
}
#endif

}  // namespace crypto
