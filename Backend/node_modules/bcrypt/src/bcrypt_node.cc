#define NAPI_VERSION 3

#include <napi.h>

#include <string>
#include <cstring>
#include <vector>
#include <stdlib.h> // atoi

#include "node_blf.h"

#define NODE_LESS_THAN (!(NODE_VERSION_AT_LEAST(0, 5, 4)))

namespace {

    bool ValidateSalt(const char* salt) {

        if (!salt || *salt != '$') {
            return false;
        }

        // discard $
        salt++;

        if (*salt > BCRYPT_VERSION) {
            return false;
        }

        if (salt[1] != '$') {
            switch (salt[1]) {
            case 'a':
            case 'b':
                salt++;
                break;
            default:
                return false;
            }
        }

        // discard version + $
        salt += 2;

        if (salt[2] != '$') {
            return false;
        }

        int n = atoi(salt);
        if (n > 31 || n < 0) {
            return false;
        }

        if (((uint8_t)1 << (uint8_t)n) < BCRYPT_MINROUNDS) {
            return false;
        }

        salt += 3;
        if (strlen(salt) * 3 / 4 < BCRYPT_MAXSALT) {
            return false;
        }

        return true;
    }

    inline char ToCharVersion(const std::string& str) {
        return str[0];
    }

    /* SALT GENERATION */

    class SaltAsyncWorker : public Napi::AsyncWorker {
        public:
            SaltAsyncWorker(const Napi::Function& callback, const std::string& seed, ssize_t rounds, char minor_ver)
                : Napi::AsyncWorker(callback, "bcrypt:SaltAsyncWorker"), seed(seed), rounds(rounds), minor_ver(minor_ver) {
            }

            ~SaltAsyncWorker() {}

            void Execute() {
                bcrypt_gensalt(minor_ver, rounds, (u_int8_t *)&seed[0], salt);
            }

            void OnOK() {
                Napi::HandleScope scope(Env());
                Callback().Call({Env().Undefined(), Napi::String::New(Env(), salt)});
            }

        private:
            std::string seed;
            ssize_t rounds;
            char minor_ver;
            char salt[_SALT_LEN];
    };

    Napi::Value GenerateSalt(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        if (info.Length() < 4) {
            throw Napi::TypeError::New(env, "4 arguments expected");
        }
        if (!info[0].IsString()) {
            throw Napi::TypeError::New(env, "First argument must be a string");
        }
        if (!info[2].IsBuffer() || (info[2].As<Napi::Buffer<char>>()).Length() != 16) {
            throw Napi::TypeError::New(env, "Second argument must be a 16 byte Buffer");
        }

        const char minor_ver = ToCharVersion(info[0].As<Napi::String>());
        const int32_t rounds = info[1].As<Napi::Number>();
        Napi::Buffer<char> seed = info[2].As<Napi::Buffer<char>>();
        Napi::Function callback = info[3].As<Napi::Function>();
        SaltAsyncWorker* saltWorker = new SaltAsyncWorker(callback, std::string(seed.Data(), 16), rounds, minor_ver);
        saltWorker->Queue();
        return env.Undefined();
    }

    Napi::Value GenerateSaltSync(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        if (info.Length() < 3) {
            throw Napi::TypeError::New(env, "3 arguments expected");
        }
        if (!info[0].IsString()) {
            throw Napi::TypeError::New(env, "First argument must be a string");
        }
        if (!info[2].IsBuffer() || (info[2].As<Napi::Buffer<char>>()).Length() != 16) {
            throw Napi::TypeError::New(env, "Third argument must be a 16 byte Buffer");
        }
        const char minor_ver = ToCharVersion(info[0].As<Napi::String>());
        const int32_t rounds = info[1].As<Napi::Number>();
        Napi::Buffer<u_int8_t> buffer = info[2].As<Napi::Buffer<u_int8_t>>();
        u_int8_t* seed = (u_int8_t*) buffer.Data();
        char salt[_SALT_LEN];
        bcrypt_gensalt(minor_ver, rounds, seed, salt);
        return Napi::String::New(env, salt, strlen(salt));
    }

    inline std::string BufferToString(const Napi::Buffer<char> &buf) {
        return std::string(buf.Data(), buf.Length());
    }

    /* ENCRYPT DATA - USED TO BE HASHPW */

    class EncryptAsyncWorker : public Napi::AsyncWorker {
        public:
            EncryptAsyncWorker(const Napi::Function& callback, const std::string& input, const std::string& salt)
                : Napi::AsyncWorker(callback, "bcrypt:EncryptAsyncWorker"), input(input), salt(salt) {
            }

            ~EncryptAsyncWorker() {}

            void Execute() {
                if (!(ValidateSalt(salt.c_str()))) {
                    SetError("Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue");
                }
                bcrypt(input.c_str(), input.length(), salt.c_str(), bcrypted);
            }

            void OnOK() {
                Napi::HandleScope scope(Env());
                Callback().Call({Env().Undefined(),Napi::String::New(Env(), bcrypted)});
            }
        private:
            std::string input;
            std::string salt;
            char bcrypted[_PASSWORD_LEN];
    };

    Napi::Value Encrypt(const Napi::CallbackInfo& info) {
        if (info.Length() < 3) {
            throw Napi::TypeError::New(info.Env(), "3 arguments expected");
        }
        std::string data = info[0].IsBuffer()
            ? BufferToString(info[0].As<Napi::Buffer<char>>())
            : info[0].As<Napi::String>();
        std::string salt = info[1].As<Napi::String>();
        Napi::Function callback = info[2].As<Napi::Function>();
        EncryptAsyncWorker* encryptWorker = new EncryptAsyncWorker(callback, data, salt);
        encryptWorker->Queue();
        return info.Env().Undefined();
    }

    Napi::Value EncryptSync(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        if (info.Length() < 2) {
            throw Napi::TypeError::New(info.Env(), "2 arguments expected");
        }
        std::string data = info[0].IsBuffer()
            ? BufferToString(info[0].As<Napi::Buffer<char>>())
            : info[0].As<Napi::String>();
        std::string salt = info[1].As<Napi::String>();
        if (!(ValidateSalt(salt.c_str()))) {
            throw Napi::Error::New(env, "Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue");
        }
        char bcrypted[_PASSWORD_LEN];
        bcrypt(data.c_str(), data.length(), salt.c_str(), bcrypted);
        return Napi::String::New(env, bcrypted, strlen(bcrypted));
    }

    /* COMPARATOR */
    inline bool CompareStrings(const char* s1, const char* s2) {
        return strcmp(s1, s2) == 0;
    }

    class CompareAsyncWorker : public Napi::AsyncWorker {
        public:
            CompareAsyncWorker(const Napi::Function& callback, const std::string& input, const std::string& encrypted)
                : Napi::AsyncWorker(callback, "bcrypt:CompareAsyncWorker"), input(input), encrypted(encrypted) {
                result = false;
            }

            ~CompareAsyncWorker() {}

            void Execute() {
                char bcrypted[_PASSWORD_LEN];
                if (ValidateSalt(encrypted.c_str())) {
                    bcrypt(input.c_str(), input.length(), encrypted.c_str(), bcrypted);
                    result = CompareStrings(bcrypted, encrypted.c_str());
                }
            }

            void OnOK() {
                Napi::HandleScope scope(Env());
                Callback().Call({Env().Undefined(), Napi::Boolean::New(Env(), result)});
            }

        private:
            std::string input;
            std::string encrypted;
            bool result;
    };

    Napi::Value Compare(const Napi::CallbackInfo& info) {
        if (info.Length() < 3) {
                throw Napi::TypeError::New(info.Env(), "3 arguments expected");
        }
        std::string input = info[0].IsBuffer()
            ? BufferToString(info[0].As<Napi::Buffer<char>>())
            : info[0].As<Napi::String>();
        std::string encrypted = info[1].As<Napi::String>();
        Napi::Function callback = info[2].As<Napi::Function>();
        CompareAsyncWorker* compareWorker = new CompareAsyncWorker(callback, input, encrypted);
        compareWorker->Queue();
        return info.Env().Undefined();
    }

    Napi::Value CompareSync(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        if (info.Length() < 2) {
            throw Napi::TypeError::New(info.Env(), "2 arguments expected");
        }
        std::string pw = info[0].IsBuffer()
            ? BufferToString(info[0].As<Napi::Buffer<char>>())
            : info[0].As<Napi::String>();
        std::string hash = info[1].As<Napi::String>();
        char bcrypted[_PASSWORD_LEN];
        if (ValidateSalt(hash.c_str())) {
            bcrypt(pw.c_str(), pw.length(), hash.c_str(), bcrypted);
            return Napi::Boolean::New(env, CompareStrings(bcrypted, hash.c_str()));
        } else {
            return Napi::Boolean::New(env, false);
        }
    }

    Napi::Value GetRounds(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        if (info.Length() < 1) {
            throw Napi::TypeError::New(env, "1 argument expected");
        }
        std::string hash =  info[0].As<Napi::String>();
        u_int32_t rounds;
        if (!(rounds = bcrypt_get_rounds(hash.c_str()))) {
            throw Napi::Error::New(env, "invalid hash provided");
        }
        return Napi::Number::New(env, rounds);
    }

} // anonymous namespace

Napi::Object init(Napi::Env env, Napi::Object exports) {
    exports.Set(Napi::String::New(env, "gen_salt_sync"), Napi::Function::New(env, GenerateSaltSync));
    exports.Set(Napi::String::New(env, "encrypt_sync"), Napi::Function::New(env, EncryptSync));
    exports.Set(Napi::String::New(env, "compare_sync"), Napi::Function::New(env, CompareSync));
    exports.Set(Napi::String::New(env, "get_rounds"), Napi::Function::New(env, GetRounds));
    exports.Set(Napi::String::New(env, "gen_salt"), Napi::Function::New(env, GenerateSalt));
    exports.Set(Napi::String::New(env, "encrypt"), Napi::Function::New(env, Encrypt));
    exports.Set(Napi::String::New(env, "compare"), Napi::Function::New(env, Compare));
    return exports;
}

NODE_API_MODULE(NODE_GYP_MODULE_NAME, init)
