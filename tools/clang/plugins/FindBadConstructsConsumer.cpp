// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "FindBadConstructsConsumer.h"

#include "clang/Frontend/CompilerInstance.h"
#include "clang/AST/Attr.h"
#include "clang/Lex/Lexer.h"
#include "llvm/Support/raw_ostream.h"

using namespace clang;

namespace chrome_checker {

namespace {

const char kMethodRequiresOverride[] =
    "[chromium-style] Overriding method must be marked with 'override' or "
    "'final'.";
const char kRedundantVirtualSpecifier[] =
    "[chromium-style] %0 is redundant; %1 implies %0.";
// http://llvm.org/bugs/show_bug.cgi?id=21051 has been filed to make this a
// Clang warning.
const char kBaseMethodVirtualAndFinal[] =
    "[chromium-style] The virtual method does not override anything and is "
    "final; consider making it non-virtual.";
const char kNoExplicitDtor[] =
    "[chromium-style] Classes that are ref-counted should have explicit "
    "destructors that are declared protected or private.";
const char kPublicDtor[] =
    "[chromium-style] Classes that are ref-counted should have "
    "destructors that are declared protected or private.";
const char kProtectedNonVirtualDtor[] =
    "[chromium-style] Classes that are ref-counted and have non-private "
    "destructors should declare their destructor virtual.";
const char kWeakPtrFactoryOrder[] =
    "[chromium-style] WeakPtrFactory members which refer to their outer class "
    "must be the last member in the outer class definition.";
const char kBadLastEnumValue[] =
    "[chromium-style] _LAST/Last constants of enum types must have the maximal "
    "value for any constant of that type.";
const char kNoteInheritance[] = "[chromium-style] %0 inherits from %1 here";
const char kNoteImplicitDtor[] =
    "[chromium-style] No explicit destructor for %0 defined";
const char kNotePublicDtor[] =
    "[chromium-style] Public destructor declared here";
const char kNoteProtectedNonVirtualDtor[] =
    "[chromium-style] Protected non-virtual destructor declared here";

bool TypeHasNonTrivialDtor(const Type* type) {
  if (const CXXRecordDecl* cxx_r = type->getPointeeCXXRecordDecl())
    return !cxx_r->hasTrivialDestructor();

  return false;
}

// Returns the underlying Type for |type| by expanding typedefs and removing
// any namespace qualifiers. This is similar to desugaring, except that for
// ElaboratedTypes, desugar will unwrap too much.
const Type* UnwrapType(const Type* type) {
  if (const ElaboratedType* elaborated = dyn_cast<ElaboratedType>(type))
    return UnwrapType(elaborated->getNamedType().getTypePtr());
  if (const TypedefType* typedefed = dyn_cast<TypedefType>(type))
    return UnwrapType(typedefed->desugar().getTypePtr());
  return type;
}

bool IsGtestTestFixture(const CXXRecordDecl* decl) {
  return decl->getQualifiedNameAsString() == "testing::Test";
}

// Generates a fixit hint to remove the 'virtual' keyword.
// Unfortunately, there doesn't seem to be a good way to determine the source
// location of the 'virtual' keyword. It's available in Declarator, but that
// isn't accessible from the AST. So instead, make an educated guess that the
// first token is probably the virtual keyword. Strictly speaking, this doesn't
// have to be true, but it probably will be.
// TODO(dcheng): Add a warning to force virtual to always appear first ;-)
FixItHint FixItRemovalForVirtual(const SourceManager& manager,
                                 const LangOptions& lang_opts,
                                 const CXXMethodDecl* method) {
  SourceRange range(method->getLocStart());
  // Get the spelling loc just in case it was expanded from a macro.
  SourceRange spelling_range(manager.getSpellingLoc(range.getBegin()));
  // Sanity check that the text looks like virtual.
  StringRef text = clang::Lexer::getSourceText(
      CharSourceRange::getTokenRange(spelling_range), manager, lang_opts);
  if (text.trim() != "virtual")
    return FixItHint();
  return FixItHint::CreateRemoval(range);
}

bool IsPodOrTemplateType(const CXXRecordDecl& record) {
  return record.isPOD() ||
         record.getDescribedClassTemplate() ||
         record.getTemplateSpecializationKind() ||
         record.isDependentType();
}

}  // namespace

FindBadConstructsConsumer::FindBadConstructsConsumer(CompilerInstance& instance,
                                                     const Options& options)
    : ChromeClassTester(instance, options) {
  // Messages for virtual method specifiers.
  diag_method_requires_override_ =
      diagnostic().getCustomDiagID(getErrorLevel(), kMethodRequiresOverride);
  diag_redundant_virtual_specifier_ =
      diagnostic().getCustomDiagID(getErrorLevel(), kRedundantVirtualSpecifier);
  diag_base_method_virtual_and_final_ =
      diagnostic().getCustomDiagID(getErrorLevel(), kBaseMethodVirtualAndFinal);

  // Messages for destructors.
  diag_no_explicit_dtor_ =
      diagnostic().getCustomDiagID(getErrorLevel(), kNoExplicitDtor);
  diag_public_dtor_ =
      diagnostic().getCustomDiagID(getErrorLevel(), kPublicDtor);
  diag_protected_non_virtual_dtor_ =
      diagnostic().getCustomDiagID(getErrorLevel(), kProtectedNonVirtualDtor);

  // Miscellaneous messages.
  diag_weak_ptr_factory_order_ =
      diagnostic().getCustomDiagID(getErrorLevel(), kWeakPtrFactoryOrder);
  diag_bad_enum_last_value_ =
      diagnostic().getCustomDiagID(getErrorLevel(), kBadLastEnumValue);

  // Registers notes to make it easier to interpret warnings.
  diag_note_inheritance_ =
      diagnostic().getCustomDiagID(DiagnosticsEngine::Note, kNoteInheritance);
  diag_note_implicit_dtor_ =
      diagnostic().getCustomDiagID(DiagnosticsEngine::Note, kNoteImplicitDtor);
  diag_note_public_dtor_ =
      diagnostic().getCustomDiagID(DiagnosticsEngine::Note, kNotePublicDtor);
  diag_note_protected_non_virtual_dtor_ = diagnostic().getCustomDiagID(
      DiagnosticsEngine::Note, kNoteProtectedNonVirtualDtor);
}

bool FindBadConstructsConsumer::VisitDecl(clang::Decl* decl) {
  clang::TagDecl* tag_decl = dyn_cast<clang::TagDecl>(decl);
  if (tag_decl && tag_decl->isCompleteDefinition())
    CheckTag(tag_decl);
  return true;
}

void FindBadConstructsConsumer::CheckChromeClass(SourceLocation record_location,
                                                 CXXRecordDecl* record) {
  // By default, the clang checker doesn't check some types (templates, etc).
  // That was only a mistake; once Chromium code passes these checks, we should
  // remove the "check-templates" option and remove this code.
  // See crbug.com/441916
  if (!options_.check_templates && IsPodOrTemplateType(*record))
    return;

  bool implementation_file = InImplementationFile(record_location);

  if (!implementation_file) {
    // Only check for "heavy" constructors/destructors in header files;
    // within implementation files, there is no performance cost.

    // If this is a POD or a class template or a type dependent on a
    // templated class, assume there's no ctor/dtor/virtual method
    // optimization that we should do.
    if (!IsPodOrTemplateType(*record))
      CheckCtorDtorWeight(record_location, record);
  }

  bool warn_on_inline_bodies = !implementation_file;
  // Check that all virtual methods are annotated with override or final.
  // Note this could also apply to templates, but for some reason Clang
  // does not always see the "override", so we get false positives.
  // See http://llvm.org/bugs/show_bug.cgi?id=18440 and
  //     http://llvm.org/bugs/show_bug.cgi?id=21942
  if (!IsPodOrTemplateType(*record))
    CheckVirtualMethods(record_location, record, warn_on_inline_bodies);

  CheckRefCountedDtors(record_location, record);

  CheckWeakPtrFactoryMembers(record_location, record);
}

void FindBadConstructsConsumer::CheckChromeEnum(SourceLocation enum_location,
                                                EnumDecl* enum_decl) {
  if (!options_.check_enum_last_value)
    return;

  bool got_one = false;
  bool is_signed = false;
  llvm::APSInt max_so_far;
  EnumDecl::enumerator_iterator iter;
  for (iter = enum_decl->enumerator_begin();
       iter != enum_decl->enumerator_end();
       ++iter) {
    llvm::APSInt current_value = iter->getInitVal();
    if (!got_one) {
      max_so_far = current_value;
      is_signed = current_value.isSigned();
      got_one = true;
    } else {
      if (is_signed != current_value.isSigned()) {
        // This only happens in some cases when compiling C (not C++) files,
        // so it is OK to bail out here.
        return;
      }
      if (current_value > max_so_far)
        max_so_far = current_value;
    }
  }
  for (iter = enum_decl->enumerator_begin();
       iter != enum_decl->enumerator_end();
       ++iter) {
    std::string name = iter->getNameAsString();
    if (((name.size() > 4 && name.compare(name.size() - 4, 4, "Last") == 0) ||
         (name.size() > 5 && name.compare(name.size() - 5, 5, "_LAST") == 0)) &&
        iter->getInitVal() < max_so_far) {
      diagnostic().Report(iter->getLocation(), diag_bad_enum_last_value_);
    }
  }
}

void FindBadConstructsConsumer::CheckCtorDtorWeight(
    SourceLocation record_location,
    CXXRecordDecl* record) {
  // We don't handle anonymous structs. If this record doesn't have a
  // name, it's of the form:
  //
  // struct {
  //   ...
  // } name_;
  if (record->getIdentifier() == NULL)
    return;

  // Count the number of templated base classes as a feature of whether the
  // destructor can be inlined.
  int templated_base_classes = 0;
  for (CXXRecordDecl::base_class_const_iterator it = record->bases_begin();
       it != record->bases_end();
       ++it) {
    if (it->getTypeSourceInfo()->getTypeLoc().getTypeLocClass() ==
        TypeLoc::TemplateSpecialization) {
      ++templated_base_classes;
    }
  }

  // Count the number of trivial and non-trivial member variables.
  int trivial_member = 0;
  int non_trivial_member = 0;
  int templated_non_trivial_member = 0;
  for (RecordDecl::field_iterator it = record->field_begin();
       it != record->field_end();
       ++it) {
    CountType(it->getType().getTypePtr(),
              &trivial_member,
              &non_trivial_member,
              &templated_non_trivial_member);
  }

  // Check to see if we need to ban inlined/synthesized constructors. Note
  // that the cutoffs here are kind of arbitrary. Scores over 10 break.
  int dtor_score = 0;
  // Deriving from a templated base class shouldn't be enough to trigger
  // the ctor warning, but if you do *anything* else, it should.
  //
  // TODO(erg): This is motivated by templated base classes that don't have
  // any data members. Somehow detect when templated base classes have data
  // members and treat them differently.
  dtor_score += templated_base_classes * 9;
  // Instantiating a template is an insta-hit.
  dtor_score += templated_non_trivial_member * 10;
  // The fourth normal class member should trigger the warning.
  dtor_score += non_trivial_member * 3;

  int ctor_score = dtor_score;
  // You should be able to have 9 ints before we warn you.
  ctor_score += trivial_member;

  if (ctor_score >= 10) {
    if (!record->hasUserDeclaredConstructor()) {
      emitWarning(record_location,
                  "Complex class/struct needs an explicit out-of-line "
                  "constructor.");
    } else {
      // Iterate across all the constructors in this file and yell if we
      // find one that tries to be inline.
      for (CXXRecordDecl::ctor_iterator it = record->ctor_begin();
           it != record->ctor_end();
           ++it) {
        // The current check is buggy. An implicit copy constructor does not
        // have an inline body, so this check never fires for classes with a
        // user-declared out-of-line constructor.
        if (it->hasInlineBody()) {
          if (it->isCopyConstructor() &&
              !record->hasUserDeclaredCopyConstructor()) {
            // In general, implicit constructors are generated on demand.  But
            // in the Windows component build, dllexport causes instantiation of
            // the copy constructor which means that this fires on many more
            // classes. For now, suppress this on dllexported classes.
            // (This does mean that windows component builds will not emit this
            // warning in some cases where it is emitted in other configs, but
            // that's the better tradeoff at this point).
            // TODO(dcheng): With the RecursiveASTVisitor, these warnings might
            // be emitted on other platforms too, reevaluate if we want to keep
            // surpressing this then http://crbug.com/467288
            if (!record->hasAttr<DLLExportAttr>())
              emitWarning(record_location,
                          "Complex class/struct needs an explicit out-of-line "
                          "copy constructor.");
          } else {
            // See the comment in the previous branch about copy constructors.
            // This does the same for implicit move constructors.
            bool is_likely_compiler_generated_dllexport_move_ctor =
                it->isMoveConstructor() &&
                !record->hasUserDeclaredMoveConstructor() &&
                record->hasAttr<DLLExportAttr>();
            if (!is_likely_compiler_generated_dllexport_move_ctor)
              emitWarning(it->getInnerLocStart(),
                          "Complex constructor has an inlined body.");
          }
        } else if (it->isInlined() && !it->isInlineSpecified() &&
                   !it->isDeleted() && (!it->isCopyOrMoveConstructor() ||
                                        it->isExplicitlyDefaulted())) {
          // isInlined() is a more reliable check than hasInlineBody(), but
          // unfortunately, it results in warnings for implicit copy/move
          // constructors in the previously mentioned situation. To preserve
          // compatibility with existing Chromium code, only warn if it's an
          // explicitly defaulted copy or move constructor.
          emitWarning(it->getInnerLocStart(),
                      "Complex constructor has an inlined body.");
        }
      }
    }
  }

  // The destructor side is equivalent except that we don't check for
  // trivial members; 20 ints don't need a destructor.
  if (dtor_score >= 10 && !record->hasTrivialDestructor()) {
    if (!record->hasUserDeclaredDestructor()) {
      emitWarning(record_location,
                  "Complex class/struct needs an explicit out-of-line "
                  "destructor.");
    } else if (CXXDestructorDecl* dtor = record->getDestructor()) {
      if (dtor->isInlined() && !dtor->isInlineSpecified() &&
          !dtor->isDeleted()) {
        emitWarning(dtor->getInnerLocStart(),
                    "Complex destructor has an inline body.");
      }
    }
  }
}

bool FindBadConstructsConsumer::InTestingNamespace(const Decl* record) {
  return GetNamespace(record).find("testing") != std::string::npos;
}

bool FindBadConstructsConsumer::IsMethodInBannedOrTestingNamespace(
    const CXXMethodDecl* method) {
  if (InBannedNamespace(method))
    return true;
  for (CXXMethodDecl::method_iterator i = method->begin_overridden_methods();
       i != method->end_overridden_methods();
       ++i) {
    const CXXMethodDecl* overridden = *i;
    if (IsMethodInBannedOrTestingNamespace(overridden) ||
        // Provide an exception for ::testing::Test. gtest itself uses some
        // magic to try to make sure SetUp()/TearDown() aren't capitalized
        // incorrectly, but having the plugin enforce override is also nice.
        (InTestingNamespace(overridden) &&
         !IsGtestTestFixture(overridden->getParent()))) {
      return true;
    }
  }

  return false;
}

SuppressibleDiagnosticBuilder
FindBadConstructsConsumer::ReportIfSpellingLocNotIgnored(
    SourceLocation loc,
    unsigned diagnostic_id) {
  return SuppressibleDiagnosticBuilder(
      &diagnostic(), loc, diagnostic_id,
      InBannedDirectory(instance().getSourceManager().getSpellingLoc(loc)));
}

// Checks that virtual methods are correctly annotated, and have no body in a
// header file.
void FindBadConstructsConsumer::CheckVirtualMethods(
    SourceLocation record_location,
    CXXRecordDecl* record,
    bool warn_on_inline_bodies) {
  // Gmock objects trigger these for each MOCK_BLAH() macro used. So we have a
  // trick to get around that. If a class has member variables whose types are
  // in the "testing" namespace (which is how gmock works behind the scenes),
  // there's a really high chance we won't care about these errors
  for (CXXRecordDecl::field_iterator it = record->field_begin();
       it != record->field_end();
       ++it) {
    CXXRecordDecl* record_type = it->getTypeSourceInfo()
                                     ->getTypeLoc()
                                     .getTypePtr()
                                     ->getAsCXXRecordDecl();
    if (record_type) {
      if (InTestingNamespace(record_type)) {
        return;
      }
    }
  }

  for (CXXRecordDecl::method_iterator it = record->method_begin();
       it != record->method_end();
       ++it) {
    if (it->isCopyAssignmentOperator() || isa<CXXConstructorDecl>(*it)) {
      // Ignore constructors and assignment operators.
    } else if (isa<CXXDestructorDecl>(*it) &&
               !record->hasUserDeclaredDestructor()) {
      // Ignore non-user-declared destructors.
    } else if (!it->isVirtual()) {
      continue;
    } else {
      CheckVirtualSpecifiers(*it);
      if (warn_on_inline_bodies)
        CheckVirtualBodies(*it);
    }
  }
}

// Makes sure that virtual methods use the most appropriate specifier. If a
// virtual method overrides a method from a base class, only the override
// specifier should be used. If the method should not be overridden by derived
// classes, only the final specifier should be used.
void FindBadConstructsConsumer::CheckVirtualSpecifiers(
    const CXXMethodDecl* method) {
  bool is_override = method->size_overridden_methods() > 0;
  bool has_virtual = method->isVirtualAsWritten();
  OverrideAttr* override_attr = method->getAttr<OverrideAttr>();
  FinalAttr* final_attr = method->getAttr<FinalAttr>();

  if (IsMethodInBannedOrTestingNamespace(method))
    return;

  SourceManager& manager = instance().getSourceManager();
  const LangOptions& lang_opts = instance().getLangOpts();

  // Complain if a method is annotated virtual && (override || final).
  if (has_virtual && (override_attr || final_attr)) {
    // ... but only if virtual does not originate in a macro from a banned file.
    // Note this is just an educated guess: the assumption here is that any
    // macro for declaring methods will probably be at the start of the method's
    // source range.
    ReportIfSpellingLocNotIgnored(method->getLocStart(),
                                  diag_redundant_virtual_specifier_)
        << "'virtual'"
        << (override_attr ? static_cast<Attr*>(override_attr) : final_attr)
        << FixItRemovalForVirtual(manager, lang_opts, method);
  }

  // Complain if a method is an override and is not annotated with override or
  // final.
  if (is_override && !override_attr && !final_attr) {
    SourceRange range = method->getSourceRange();
    SourceLocation loc;
    if (method->hasInlineBody()) {
      loc = method->getBody()->getSourceRange().getBegin();
    } else {
      loc = Lexer::getLocForEndOfToken(manager.getSpellingLoc(range.getEnd()),
                                       0, manager, lang_opts);
      // The original code used the ending source loc of TypeSourceInfo's
      // TypeLoc. Unfortunately, this breaks down in the presence of attributes.
      // Attributes often appear at the end of a TypeLoc, e.g.
      //   virtual ULONG __stdcall AddRef()
      // has a TypeSourceInfo that looks something like:
      //   ULONG AddRef() __attribute(stdcall)
      // so a fix-it insertion would be generated to insert 'override' after
      // __stdcall in the code as written.
      // While using the spelling loc of the CXXMethodDecl fixes attribute
      // handling, it breaks handling of "= 0" and similar constructs.. To work
      // around this, scan backwards in the source text for a '=' or ')' token
      // and adjust the location as needed...
      for (SourceLocation l = loc.getLocWithOffset(-1);
           l != manager.getLocForStartOfFile(manager.getFileID(loc));
           l = l.getLocWithOffset(-1)) {
        l = Lexer::GetBeginningOfToken(l, manager, lang_opts);
        Token token;
        // getRawToken() returns *true* on failure. In that case, just give up
        // and don't bother generating a possibly incorrect fix-it.
        if (Lexer::getRawToken(l, token, manager, lang_opts, true)) {
          loc = SourceLocation();
          break;
        }
        if (token.is(tok::r_paren)) {
          break;
        } else if (token.is(tok::equal)) {
          loc = l;
          break;
        }
      }
    }
    // Again, only emit the warning if it doesn't originate from a macro in
    // a system header.
    if (loc.isValid()) {
      ReportIfSpellingLocNotIgnored(loc, diag_method_requires_override_)
          << FixItHint::CreateInsertion(loc, " override");
    } else {
      ReportIfSpellingLocNotIgnored(range.getBegin(),
                                    diag_method_requires_override_);
    }
  }

  if (final_attr && override_attr) {
    ReportIfSpellingLocNotIgnored(override_attr->getLocation(),
                                  diag_redundant_virtual_specifier_)
        << override_attr << final_attr
        << FixItHint::CreateRemoval(override_attr->getRange());
  }

  if (final_attr && !is_override) {
    ReportIfSpellingLocNotIgnored(method->getLocStart(),
                                  diag_base_method_virtual_and_final_)
        << FixItRemovalForVirtual(manager, lang_opts, method)
        << FixItHint::CreateRemoval(final_attr->getRange());
  }
}

void FindBadConstructsConsumer::CheckVirtualBodies(
    const CXXMethodDecl* method) {
  // Virtual methods should not have inline definitions beyond "{}". This
  // only matters for header files.
  if (method->hasBody() && method->hasInlineBody()) {
    if (CompoundStmt* cs = dyn_cast<CompoundStmt>(method->getBody())) {
      if (cs->size()) {
        SourceLocation loc = cs->getLBracLoc();
        // CR_BEGIN_MSG_MAP_EX and BEGIN_SAFE_MSG_MAP_EX try to be compatible
        // to BEGIN_MSG_MAP(_EX).  So even though they are in chrome code,
        // we can't easily fix them, so explicitly whitelist them here.
        bool emit = true;
        if (loc.isMacroID()) {
          SourceManager& manager = instance().getSourceManager();
          if (InBannedDirectory(manager.getSpellingLoc(loc)))
            emit = false;
          else {
            StringRef name = Lexer::getImmediateMacroName(
                loc, manager, instance().getLangOpts());
            if (name == "CR_BEGIN_MSG_MAP_EX" ||
                name == "BEGIN_SAFE_MSG_MAP_EX")
              emit = false;
          }
        }
        if (emit)
          emitWarning(loc,
                      "virtual methods with non-empty bodies shouldn't be "
                      "declared inline.");
      }
    }
  }
}

void FindBadConstructsConsumer::CountType(const Type* type,
                                          int* trivial_member,
                                          int* non_trivial_member,
                                          int* templated_non_trivial_member) {
  switch (type->getTypeClass()) {
    case Type::Record: {
      // Simplifying; the whole class isn't trivial if the dtor is, but
      // we use this as a signal about complexity.
      if (TypeHasNonTrivialDtor(type))
        (*trivial_member)++;
      else
        (*non_trivial_member)++;
      break;
    }
    case Type::TemplateSpecialization: {
      TemplateName name =
          dyn_cast<TemplateSpecializationType>(type)->getTemplateName();
      bool whitelisted_template = false;

      // HACK: I'm at a loss about how to get the syntax checker to get
      // whether a template is externed or not. For the first pass here,
      // just do retarded string comparisons.
      if (TemplateDecl* decl = name.getAsTemplateDecl()) {
        std::string base_name = decl->getNameAsString();
        if (base_name == "basic_string")
          whitelisted_template = true;
      }

      if (whitelisted_template)
        (*non_trivial_member)++;
      else
        (*templated_non_trivial_member)++;
      break;
    }
    case Type::Elaborated: {
      CountType(dyn_cast<ElaboratedType>(type)->getNamedType().getTypePtr(),
                trivial_member,
                non_trivial_member,
                templated_non_trivial_member);
      break;
    }
    case Type::Typedef: {
      while (const TypedefType* TT = dyn_cast<TypedefType>(type)) {
        type = TT->getDecl()->getUnderlyingType().getTypePtr();
      }
      CountType(type,
                trivial_member,
                non_trivial_member,
                templated_non_trivial_member);
      break;
    }
    default: {
      // Stupid assumption: anything we see that isn't the above is one of
      // the 20 integer types.
      (*trivial_member)++;
      break;
    }
  }
}

// Check |record| for issues that are problematic for ref-counted types.
// Note that |record| may not be a ref-counted type, but a base class for
// a type that is.
// If there are issues, update |loc| with the SourceLocation of the issue
// and returns appropriately, or returns None if there are no issues.
FindBadConstructsConsumer::RefcountIssue
FindBadConstructsConsumer::CheckRecordForRefcountIssue(
    const CXXRecordDecl* record,
    SourceLocation& loc) {
  if (!record->hasUserDeclaredDestructor()) {
    loc = record->getLocation();
    return ImplicitDestructor;
  }

  if (CXXDestructorDecl* dtor = record->getDestructor()) {
    if (dtor->getAccess() == AS_public) {
      loc = dtor->getInnerLocStart();
      return PublicDestructor;
    }
  }

  return None;
}

// Returns true if |base| specifies one of the Chromium reference counted
// classes (base::RefCounted / base::RefCountedThreadSafe).
bool FindBadConstructsConsumer::IsRefCountedCallback(
    const CXXBaseSpecifier* base,
    CXXBasePath& path,
    void* user_data) {
  FindBadConstructsConsumer* self =
      static_cast<FindBadConstructsConsumer*>(user_data);

  const TemplateSpecializationType* base_type =
      dyn_cast<TemplateSpecializationType>(
          UnwrapType(base->getType().getTypePtr()));
  if (!base_type) {
    // Base-most definition is not a template, so this cannot derive from
    // base::RefCounted. However, it may still be possible to use with a
    // scoped_refptr<> and support ref-counting, so this is not a perfect
    // guarantee of safety.
    return false;
  }

  TemplateName name = base_type->getTemplateName();
  if (TemplateDecl* decl = name.getAsTemplateDecl()) {
    std::string base_name = decl->getNameAsString();

    // Check for both base::RefCounted and base::RefCountedThreadSafe.
    if (base_name.compare(0, 10, "RefCounted") == 0 &&
        self->GetNamespace(decl) == "base") {
      return true;
    }
  }

  return false;
}

// Returns true if |base| specifies a class that has a public destructor,
// either explicitly or implicitly.
bool FindBadConstructsConsumer::HasPublicDtorCallback(
    const CXXBaseSpecifier* base,
    CXXBasePath& path,
    void* user_data) {
  // Only examine paths that have public inheritance, as they are the
  // only ones which will result in the destructor potentially being
  // exposed. This check is largely redundant, as Chromium code should be
  // exclusively using public inheritance.
  if (path.Access != AS_public)
    return false;

  CXXRecordDecl* record =
      dyn_cast<CXXRecordDecl>(base->getType()->getAs<RecordType>()->getDecl());
  SourceLocation unused;
  return None != CheckRecordForRefcountIssue(record, unused);
}

// Outputs a C++ inheritance chain as a diagnostic aid.
void FindBadConstructsConsumer::PrintInheritanceChain(const CXXBasePath& path) {
  for (CXXBasePath::const_iterator it = path.begin(); it != path.end(); ++it) {
    diagnostic().Report(it->Base->getLocStart(), diag_note_inheritance_)
        << it->Class << it->Base->getType();
  }
}

unsigned FindBadConstructsConsumer::DiagnosticForIssue(RefcountIssue issue) {
  switch (issue) {
    case ImplicitDestructor:
      return diag_no_explicit_dtor_;
    case PublicDestructor:
      return diag_public_dtor_;
    case None:
      assert(false && "Do not call DiagnosticForIssue with issue None");
      return 0;
  }
  assert(false);
  return 0;
}

// Check |record| to determine if it has any problematic refcounting
// issues and, if so, print them as warnings/errors based on the current
// value of getErrorLevel().
//
// If |record| is a C++ class, and if it inherits from one of the Chromium
// ref-counting classes (base::RefCounted / base::RefCountedThreadSafe),
// ensure that there are no public destructors in the class hierarchy. This
// is to guard against accidentally stack-allocating a RefCounted class or
// sticking it in a non-ref-counted container (like scoped_ptr<>).
void FindBadConstructsConsumer::CheckRefCountedDtors(
    SourceLocation record_location,
    CXXRecordDecl* record) {
  // Skip anonymous structs.
  if (record->getIdentifier() == NULL)
    return;

  // Determine if the current type is even ref-counted.
  CXXBasePaths refcounted_path;
  if (!record->lookupInBases(&FindBadConstructsConsumer::IsRefCountedCallback,
                             this,
                             refcounted_path)) {
    return;  // Class does not derive from a ref-counted base class.
  }

  // Easy check: Check to see if the current type is problematic.
  SourceLocation loc;
  RefcountIssue issue = CheckRecordForRefcountIssue(record, loc);
  if (issue != None) {
    diagnostic().Report(loc, DiagnosticForIssue(issue));
    PrintInheritanceChain(refcounted_path.front());
    return;
  }
  if (CXXDestructorDecl* dtor =
          refcounted_path.begin()->back().Class->getDestructor()) {
    if (dtor->getAccess() == AS_protected && !dtor->isVirtual()) {
      loc = dtor->getInnerLocStart();
      diagnostic().Report(loc, diag_protected_non_virtual_dtor_);
      return;
    }
  }

  // Long check: Check all possible base classes for problematic
  // destructors. This checks for situations involving multiple
  // inheritance, where the ref-counted class may be implementing an
  // interface that has a public or implicit destructor.
  //
  // struct SomeInterface {
  //   virtual void DoFoo();
  // };
  //
  // struct RefCountedInterface
  //    : public base::RefCounted<RefCountedInterface>,
  //      public SomeInterface {
  //  private:
  //   friend class base::Refcounted<RefCountedInterface>;
  //   virtual ~RefCountedInterface() {}
  // };
  //
  // While RefCountedInterface is "safe", in that its destructor is
  // private, it's possible to do the following "unsafe" code:
  //   scoped_refptr<RefCountedInterface> some_class(
  //       new RefCountedInterface);
  //   // Calls SomeInterface::~SomeInterface(), which is unsafe.
  //   delete static_cast<SomeInterface*>(some_class.get());
  if (!options_.check_base_classes)
    return;

  // Find all public destructors. This will record the class hierarchy
  // that leads to the public destructor in |dtor_paths|.
  CXXBasePaths dtor_paths;
  if (!record->lookupInBases(&FindBadConstructsConsumer::HasPublicDtorCallback,
                             this,
                             dtor_paths)) {
    return;
  }

  for (CXXBasePaths::const_paths_iterator it = dtor_paths.begin();
       it != dtor_paths.end();
       ++it) {
    // The record with the problem will always be the last record
    // in the path, since it is the record that stopped the search.
    const CXXRecordDecl* problem_record = dyn_cast<CXXRecordDecl>(
        it->back().Base->getType()->getAs<RecordType>()->getDecl());

    issue = CheckRecordForRefcountIssue(problem_record, loc);

    if (issue == ImplicitDestructor) {
      diagnostic().Report(record_location, diag_no_explicit_dtor_);
      PrintInheritanceChain(refcounted_path.front());
      diagnostic().Report(loc, diag_note_implicit_dtor_) << problem_record;
      PrintInheritanceChain(*it);
    } else if (issue == PublicDestructor) {
      diagnostic().Report(record_location, diag_public_dtor_);
      PrintInheritanceChain(refcounted_path.front());
      diagnostic().Report(loc, diag_note_public_dtor_);
      PrintInheritanceChain(*it);
    }
  }
}

// Check for any problems with WeakPtrFactory class members. This currently
// only checks that any WeakPtrFactory<T> member of T appears as the last
// data member in T. We could consider checking for bad uses of
// WeakPtrFactory to refer to other data members, but that would require
// looking at the initializer list in constructors to see what the factory
// points to.
// Note, if we later add other unrelated checks of data members, we should
// consider collapsing them in to one loop to avoid iterating over the data
// members more than once.
void FindBadConstructsConsumer::CheckWeakPtrFactoryMembers(
    SourceLocation record_location,
    CXXRecordDecl* record) {
  // Skip anonymous structs.
  if (record->getIdentifier() == NULL)
    return;

  // Iterate through members of the class.
  RecordDecl::field_iterator iter(record->field_begin()),
      the_end(record->field_end());
  SourceLocation weak_ptr_factory_location;  // Invalid initially.
  for (; iter != the_end; ++iter) {
    const TemplateSpecializationType* template_spec_type =
        iter->getType().getTypePtr()->getAs<TemplateSpecializationType>();
    bool param_is_weak_ptr_factory_to_self = false;
    if (template_spec_type) {
      const TemplateDecl* template_decl =
          template_spec_type->getTemplateName().getAsTemplateDecl();
      if (template_decl && template_spec_type->getNumArgs() == 1) {
        if (template_decl->getNameAsString().compare("WeakPtrFactory") == 0 &&
            GetNamespace(template_decl) == "base") {
          // Only consider WeakPtrFactory members which are specialized for the
          // owning class.
          const TemplateArgument& arg = template_spec_type->getArg(0);
          if (arg.getAsType().getTypePtr()->getAsCXXRecordDecl() ==
              record->getTypeForDecl()->getAsCXXRecordDecl()) {
            if (!weak_ptr_factory_location.isValid()) {
              // Save the first matching WeakPtrFactory member for the
              // diagnostic.
              weak_ptr_factory_location = iter->getLocation();
            }
            param_is_weak_ptr_factory_to_self = true;
          }
        }
      }
    }
    // If we've already seen a WeakPtrFactory<OwningType> and this param is not
    // one of those, it means there is at least one member after a factory.
    if (weak_ptr_factory_location.isValid() &&
        !param_is_weak_ptr_factory_to_self) {
      diagnostic().Report(weak_ptr_factory_location,
                          diag_weak_ptr_factory_order_);
    }
  }
}

}  // namespace chrome_checker
