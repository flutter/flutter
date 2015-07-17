// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/trace_event_analyzer.h"

#include <algorithm>
#include <math.h>
#include <set>

#include "base/json/json_reader.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/pattern.h"
#include "base/values.h"

namespace trace_analyzer {

// TraceEvent

TraceEvent::TraceEvent()
    : thread(0, 0),
      timestamp(0),
      duration(0),
      phase(TRACE_EVENT_PHASE_BEGIN),
      other_event(NULL) {
}

TraceEvent::~TraceEvent() {
}

bool TraceEvent::SetFromJSON(const base::Value* event_value) {
  if (event_value->GetType() != base::Value::TYPE_DICTIONARY) {
    LOG(ERROR) << "Value must be TYPE_DICTIONARY";
    return false;
  }
  const base::DictionaryValue* dictionary =
      static_cast<const base::DictionaryValue*>(event_value);

  std::string phase_str;
  const base::DictionaryValue* args = NULL;

  if (!dictionary->GetString("ph", &phase_str)) {
    LOG(ERROR) << "ph is missing from TraceEvent JSON";
    return false;
  }

  phase = *phase_str.data();

  bool may_have_duration = (phase == TRACE_EVENT_PHASE_COMPLETE);
  bool require_origin = (phase != TRACE_EVENT_PHASE_METADATA);
  bool require_id = (phase == TRACE_EVENT_PHASE_ASYNC_BEGIN ||
                     phase == TRACE_EVENT_PHASE_ASYNC_STEP_INTO ||
                     phase == TRACE_EVENT_PHASE_ASYNC_STEP_PAST ||
                     phase == TRACE_EVENT_PHASE_ASYNC_END);

  if (require_origin && !dictionary->GetInteger("pid", &thread.process_id)) {
    LOG(ERROR) << "pid is missing from TraceEvent JSON";
    return false;
  }
  if (require_origin && !dictionary->GetInteger("tid", &thread.thread_id)) {
    LOG(ERROR) << "tid is missing from TraceEvent JSON";
    return false;
  }
  if (require_origin && !dictionary->GetDouble("ts", &timestamp)) {
    LOG(ERROR) << "ts is missing from TraceEvent JSON";
    return false;
  }
  if (may_have_duration) {
    dictionary->GetDouble("dur", &duration);
  }
  if (!dictionary->GetString("cat", &category)) {
    LOG(ERROR) << "cat is missing from TraceEvent JSON";
    return false;
  }
  if (!dictionary->GetString("name", &name)) {
    LOG(ERROR) << "name is missing from TraceEvent JSON";
    return false;
  }
  if (!dictionary->GetDictionary("args", &args)) {
    LOG(ERROR) << "args is missing from TraceEvent JSON";
    return false;
  }
  if (require_id && !dictionary->GetString("id", &id)) {
    LOG(ERROR) << "id is missing from ASYNC_BEGIN/ASYNC_END TraceEvent JSON";
    return false;
  }

  // For each argument, copy the type and create a trace_analyzer::TraceValue.
  for (base::DictionaryValue::Iterator it(*args); !it.IsAtEnd();
       it.Advance()) {
    std::string str;
    bool boolean = false;
    int int_num = 0;
    double double_num = 0.0;
    if (it.value().GetAsString(&str)) {
      arg_strings[it.key()] = str;
    } else if (it.value().GetAsInteger(&int_num)) {
      arg_numbers[it.key()] = static_cast<double>(int_num);
    } else if (it.value().GetAsBoolean(&boolean)) {
      arg_numbers[it.key()] = static_cast<double>(boolean ? 1 : 0);
    } else if (it.value().GetAsDouble(&double_num)) {
      arg_numbers[it.key()] = double_num;
    } else {
      LOG(WARNING) << "Value type of argument is not supported: " <<
          static_cast<int>(it.value().GetType());
      continue;  // Skip non-supported arguments.
    }
  }

  return true;
}

double TraceEvent::GetAbsTimeToOtherEvent() const {
  return fabs(other_event->timestamp - timestamp);
}

bool TraceEvent::GetArgAsString(const std::string& name,
                                std::string* arg) const {
  std::map<std::string, std::string>::const_iterator i = arg_strings.find(name);
  if (i != arg_strings.end()) {
    *arg = i->second;
    return true;
  }
  return false;
}

bool TraceEvent::GetArgAsNumber(const std::string& name,
                                double* arg) const {
  std::map<std::string, double>::const_iterator i = arg_numbers.find(name);
  if (i != arg_numbers.end()) {
    *arg = i->second;
    return true;
  }
  return false;
}

bool TraceEvent::HasStringArg(const std::string& name) const {
  return (arg_strings.find(name) != arg_strings.end());
}

bool TraceEvent::HasNumberArg(const std::string& name) const {
  return (arg_numbers.find(name) != arg_numbers.end());
}

std::string TraceEvent::GetKnownArgAsString(const std::string& name) const {
  std::string arg_string;
  bool result = GetArgAsString(name, &arg_string);
  DCHECK(result);
  return arg_string;
}

double TraceEvent::GetKnownArgAsDouble(const std::string& name) const {
  double arg_double = 0;
  bool result = GetArgAsNumber(name, &arg_double);
  DCHECK(result);
  return arg_double;
}

int TraceEvent::GetKnownArgAsInt(const std::string& name) const {
  double arg_double = 0;
  bool result = GetArgAsNumber(name, &arg_double);
  DCHECK(result);
  return static_cast<int>(arg_double);
}

bool TraceEvent::GetKnownArgAsBool(const std::string& name) const {
  double arg_double = 0;
  bool result = GetArgAsNumber(name, &arg_double);
  DCHECK(result);
  return (arg_double != 0.0);
}

// QueryNode

QueryNode::QueryNode(const Query& query) : query_(query) {
}

QueryNode::~QueryNode() {
}

// Query

Query::Query(TraceEventMember member)
    : type_(QUERY_EVENT_MEMBER),
      operator_(OP_INVALID),
      member_(member),
      number_(0),
      is_pattern_(false) {
}

Query::Query(TraceEventMember member, const std::string& arg_name)
    : type_(QUERY_EVENT_MEMBER),
      operator_(OP_INVALID),
      member_(member),
      number_(0),
      string_(arg_name),
      is_pattern_(false) {
}

Query::Query(const Query& query)
    : type_(query.type_),
      operator_(query.operator_),
      left_(query.left_),
      right_(query.right_),
      member_(query.member_),
      number_(query.number_),
      string_(query.string_),
      is_pattern_(query.is_pattern_) {
}

Query::~Query() {
}

Query Query::String(const std::string& str) {
  return Query(str);
}

Query Query::Double(double num) {
  return Query(num);
}

Query Query::Int(int32 num) {
  return Query(static_cast<double>(num));
}

Query Query::Uint(uint32 num) {
  return Query(static_cast<double>(num));
}

Query Query::Bool(bool boolean) {
  return Query(boolean ? 1.0 : 0.0);
}

Query Query::Phase(char phase) {
  return Query(static_cast<double>(phase));
}

Query Query::Pattern(const std::string& pattern) {
  Query query(pattern);
  query.is_pattern_ = true;
  return query;
}

bool Query::Evaluate(const TraceEvent& event) const {
  // First check for values that can convert to bool.

  // double is true if != 0:
  double bool_value = 0.0;
  bool is_bool = GetAsDouble(event, &bool_value);
  if (is_bool)
    return (bool_value != 0.0);

  // string is true if it is non-empty:
  std::string str_value;
  bool is_str = GetAsString(event, &str_value);
  if (is_str)
    return !str_value.empty();

  DCHECK_EQ(QUERY_BOOLEAN_OPERATOR, type_)
      << "Invalid query: missing boolean expression";
  DCHECK(left_.get());
  DCHECK(right_.get() || is_unary_operator());

  if (is_comparison_operator()) {
    DCHECK(left().is_value() && right().is_value())
        << "Invalid query: comparison operator used between event member and "
           "value.";
    bool compare_result = false;
    if (CompareAsDouble(event, &compare_result))
      return compare_result;
    if (CompareAsString(event, &compare_result))
      return compare_result;
    return false;
  }
  // It's a logical operator.
  switch (operator_) {
    case OP_AND:
      return left().Evaluate(event) && right().Evaluate(event);
    case OP_OR:
      return left().Evaluate(event) || right().Evaluate(event);
    case OP_NOT:
      return !left().Evaluate(event);
    default:
      NOTREACHED();
      return false;
  }
}

bool Query::CompareAsDouble(const TraceEvent& event, bool* result) const {
  double lhs, rhs;
  if (!left().GetAsDouble(event, &lhs) || !right().GetAsDouble(event, &rhs))
    return false;
  switch (operator_) {
    case OP_EQ:
      *result = (lhs == rhs);
      return true;
    case OP_NE:
      *result = (lhs != rhs);
      return true;
    case OP_LT:
      *result = (lhs < rhs);
      return true;
    case OP_LE:
      *result = (lhs <= rhs);
      return true;
    case OP_GT:
      *result = (lhs > rhs);
      return true;
    case OP_GE:
      *result = (lhs >= rhs);
      return true;
    default:
      NOTREACHED();
      return false;
  }
}

bool Query::CompareAsString(const TraceEvent& event, bool* result) const {
  std::string lhs, rhs;
  if (!left().GetAsString(event, &lhs) || !right().GetAsString(event, &rhs))
    return false;
  switch (operator_) {
    case OP_EQ:
      if (right().is_pattern_)
        *result = base::MatchPattern(lhs, rhs);
      else if (left().is_pattern_)
        *result = base::MatchPattern(rhs, lhs);
      else
        *result = (lhs == rhs);
      return true;
    case OP_NE:
      if (right().is_pattern_)
        *result = !base::MatchPattern(lhs, rhs);
      else if (left().is_pattern_)
        *result = !base::MatchPattern(rhs, lhs);
      else
        *result = (lhs != rhs);
      return true;
    case OP_LT:
      *result = (lhs < rhs);
      return true;
    case OP_LE:
      *result = (lhs <= rhs);
      return true;
    case OP_GT:
      *result = (lhs > rhs);
      return true;
    case OP_GE:
      *result = (lhs >= rhs);
      return true;
    default:
      NOTREACHED();
      return false;
  }
}

bool Query::EvaluateArithmeticOperator(const TraceEvent& event,
                                       double* num) const {
  DCHECK_EQ(QUERY_ARITHMETIC_OPERATOR, type_);
  DCHECK(left_.get());
  DCHECK(right_.get() || is_unary_operator());

  double lhs = 0, rhs = 0;
  if (!left().GetAsDouble(event, &lhs))
    return false;
  if (!is_unary_operator() && !right().GetAsDouble(event, &rhs))
    return false;

  switch (operator_) {
    case OP_ADD:
      *num = lhs + rhs;
      return true;
    case OP_SUB:
      *num = lhs - rhs;
      return true;
    case OP_MUL:
      *num = lhs * rhs;
      return true;
    case OP_DIV:
      *num = lhs / rhs;
      return true;
    case OP_MOD:
      *num = static_cast<double>(static_cast<int64>(lhs) %
                                 static_cast<int64>(rhs));
      return true;
    case OP_NEGATE:
      *num = -lhs;
      return true;
    default:
      NOTREACHED();
      return false;
  }
}

bool Query::GetAsDouble(const TraceEvent& event, double* num) const {
  switch (type_) {
    case QUERY_ARITHMETIC_OPERATOR:
      return EvaluateArithmeticOperator(event, num);
    case QUERY_EVENT_MEMBER:
      return GetMemberValueAsDouble(event, num);
    case QUERY_NUMBER:
      *num = number_;
      return true;
    default:
      return false;
  }
}

bool Query::GetAsString(const TraceEvent& event, std::string* str) const {
  switch (type_) {
    case QUERY_EVENT_MEMBER:
      return GetMemberValueAsString(event, str);
    case QUERY_STRING:
      *str = string_;
      return true;
    default:
      return false;
  }
}

bool Query::GetMemberValueAsDouble(const TraceEvent& event,
                                   double* num) const {
  DCHECK_EQ(QUERY_EVENT_MEMBER, type_);

  // This could be a request for a member of |event| or a member of |event|'s
  // associated event. Store the target event in the_event:
  const TraceEvent* the_event = (member_ < OTHER_PID) ?
      &event : event.other_event;

  // Request for member of associated event, but there is no associated event.
  if (!the_event)
    return false;

  switch (member_) {
    case EVENT_PID:
    case OTHER_PID:
      *num = static_cast<double>(the_event->thread.process_id);
      return true;
    case EVENT_TID:
    case OTHER_TID:
      *num = static_cast<double>(the_event->thread.thread_id);
      return true;
    case EVENT_TIME:
    case OTHER_TIME:
      *num = the_event->timestamp;
      return true;
    case EVENT_DURATION:
      if (!the_event->has_other_event())
        return false;
      *num = the_event->GetAbsTimeToOtherEvent();
      return true;
    case EVENT_COMPLETE_DURATION:
      if (the_event->phase != TRACE_EVENT_PHASE_COMPLETE)
        return false;
      *num = the_event->duration;
      return true;
    case EVENT_PHASE:
    case OTHER_PHASE:
      *num = static_cast<double>(the_event->phase);
      return true;
    case EVENT_HAS_STRING_ARG:
    case OTHER_HAS_STRING_ARG:
      *num = (the_event->HasStringArg(string_) ? 1.0 : 0.0);
      return true;
    case EVENT_HAS_NUMBER_ARG:
    case OTHER_HAS_NUMBER_ARG:
      *num = (the_event->HasNumberArg(string_) ? 1.0 : 0.0);
      return true;
    case EVENT_ARG:
    case OTHER_ARG: {
      // Search for the argument name and return its value if found.
      std::map<std::string, double>::const_iterator num_i =
          the_event->arg_numbers.find(string_);
      if (num_i == the_event->arg_numbers.end())
        return false;
      *num = num_i->second;
      return true;
    }
    case EVENT_HAS_OTHER:
      // return 1.0 (true) if the other event exists
      *num = event.other_event ? 1.0 : 0.0;
      return true;
    default:
      return false;
  }
}

bool Query::GetMemberValueAsString(const TraceEvent& event,
                                   std::string* str) const {
  DCHECK_EQ(QUERY_EVENT_MEMBER, type_);

  // This could be a request for a member of |event| or a member of |event|'s
  // associated event. Store the target event in the_event:
  const TraceEvent* the_event = (member_ < OTHER_PID) ?
      &event : event.other_event;

  // Request for member of associated event, but there is no associated event.
  if (!the_event)
    return false;

  switch (member_) {
    case EVENT_CATEGORY:
    case OTHER_CATEGORY:
      *str = the_event->category;
      return true;
    case EVENT_NAME:
    case OTHER_NAME:
      *str = the_event->name;
      return true;
    case EVENT_ID:
    case OTHER_ID:
      *str = the_event->id;
      return true;
    case EVENT_ARG:
    case OTHER_ARG: {
      // Search for the argument name and return its value if found.
      std::map<std::string, std::string>::const_iterator str_i =
          the_event->arg_strings.find(string_);
      if (str_i == the_event->arg_strings.end())
        return false;
      *str = str_i->second;
      return true;
    }
    default:
      return false;
  }
}

Query::Query(const std::string& str)
    : type_(QUERY_STRING),
      operator_(OP_INVALID),
      member_(EVENT_INVALID),
      number_(0),
      string_(str),
      is_pattern_(false) {
}

Query::Query(double num)
    : type_(QUERY_NUMBER),
      operator_(OP_INVALID),
      member_(EVENT_INVALID),
      number_(num),
      is_pattern_(false) {
}
const Query& Query::left() const {
  return left_->query();
}

const Query& Query::right() const {
  return right_->query();
}

Query Query::operator==(const Query& rhs) const {
  return Query(*this, rhs, OP_EQ);
}

Query Query::operator!=(const Query& rhs) const {
  return Query(*this, rhs, OP_NE);
}

Query Query::operator<(const Query& rhs) const {
  return Query(*this, rhs, OP_LT);
}

Query Query::operator<=(const Query& rhs) const {
  return Query(*this, rhs, OP_LE);
}

Query Query::operator>(const Query& rhs) const {
  return Query(*this, rhs, OP_GT);
}

Query Query::operator>=(const Query& rhs) const {
  return Query(*this, rhs, OP_GE);
}

Query Query::operator&&(const Query& rhs) const {
  return Query(*this, rhs, OP_AND);
}

Query Query::operator||(const Query& rhs) const {
  return Query(*this, rhs, OP_OR);
}

Query Query::operator!() const {
  return Query(*this, OP_NOT);
}

Query Query::operator+(const Query& rhs) const {
  return Query(*this, rhs, OP_ADD);
}

Query Query::operator-(const Query& rhs) const {
  return Query(*this, rhs, OP_SUB);
}

Query Query::operator*(const Query& rhs) const {
  return Query(*this, rhs, OP_MUL);
}

Query Query::operator/(const Query& rhs) const {
  return Query(*this, rhs, OP_DIV);
}

Query Query::operator%(const Query& rhs) const {
  return Query(*this, rhs, OP_MOD);
}

Query Query::operator-() const {
  return Query(*this, OP_NEGATE);
}


Query::Query(const Query& left, const Query& right, Operator binary_op)
    : operator_(binary_op),
      left_(new QueryNode(left)),
      right_(new QueryNode(right)),
      member_(EVENT_INVALID),
      number_(0) {
  type_ = (binary_op < OP_ADD ?
           QUERY_BOOLEAN_OPERATOR : QUERY_ARITHMETIC_OPERATOR);
}

Query::Query(const Query& left, Operator unary_op)
    : operator_(unary_op),
      left_(new QueryNode(left)),
      member_(EVENT_INVALID),
      number_(0) {
  type_ = (unary_op < OP_ADD ?
           QUERY_BOOLEAN_OPERATOR : QUERY_ARITHMETIC_OPERATOR);
}

namespace {

// Search |events| for |query| and add matches to |output|.
size_t FindMatchingEvents(const std::vector<TraceEvent>& events,
                          const Query& query,
                          TraceEventVector* output,
                          bool ignore_metadata_events) {
  for (size_t i = 0; i < events.size(); ++i) {
    if (ignore_metadata_events && events[i].phase == TRACE_EVENT_PHASE_METADATA)
      continue;
    if (query.Evaluate(events[i]))
      output->push_back(&events[i]);
  }
  return output->size();
}

bool ParseEventsFromJson(const std::string& json,
                         std::vector<TraceEvent>* output) {
  scoped_ptr<base::Value> root;
  root.reset(base::JSONReader::DeprecatedRead(json));

  base::ListValue* root_list = NULL;
  if (!root.get() || !root->GetAsList(&root_list))
    return false;

  for (size_t i = 0; i < root_list->GetSize(); ++i) {
    base::Value* item = NULL;
    if (root_list->Get(i, &item)) {
      TraceEvent event;
      if (event.SetFromJSON(item))
        output->push_back(event);
      else
        return false;
    }
  }

  return true;
}

}  // namespace

// TraceAnalyzer

TraceAnalyzer::TraceAnalyzer()
    : ignore_metadata_events_(false),
      allow_assocation_changes_(true) {}

TraceAnalyzer::~TraceAnalyzer() {
}

// static
TraceAnalyzer* TraceAnalyzer::Create(const std::string& json_events) {
  scoped_ptr<TraceAnalyzer> analyzer(new TraceAnalyzer());
  if (analyzer->SetEvents(json_events))
    return analyzer.release();
  return NULL;
}

bool TraceAnalyzer::SetEvents(const std::string& json_events) {
  raw_events_.clear();
  if (!ParseEventsFromJson(json_events, &raw_events_))
    return false;
  std::stable_sort(raw_events_.begin(), raw_events_.end());
  ParseMetadata();
  return true;
}

void TraceAnalyzer::AssociateBeginEndEvents() {
  using trace_analyzer::Query;

  Query begin(Query::EventPhaseIs(TRACE_EVENT_PHASE_BEGIN));
  Query end(Query::EventPhaseIs(TRACE_EVENT_PHASE_END));
  Query match(Query::EventName() == Query::OtherName() &&
              Query::EventCategory() == Query::OtherCategory() &&
              Query::EventTid() == Query::OtherTid() &&
              Query::EventPid() == Query::OtherPid());

  AssociateEvents(begin, end, match);
}

void TraceAnalyzer::AssociateAsyncBeginEndEvents() {
  using trace_analyzer::Query;

  Query begin(
      Query::EventPhaseIs(TRACE_EVENT_PHASE_ASYNC_BEGIN) ||
      Query::EventPhaseIs(TRACE_EVENT_PHASE_ASYNC_STEP_INTO) ||
      Query::EventPhaseIs(TRACE_EVENT_PHASE_ASYNC_STEP_PAST));
  Query end(Query::EventPhaseIs(TRACE_EVENT_PHASE_ASYNC_END) ||
            Query::EventPhaseIs(TRACE_EVENT_PHASE_ASYNC_STEP_INTO) ||
            Query::EventPhaseIs(TRACE_EVENT_PHASE_ASYNC_STEP_PAST));
  Query match(Query::EventName() == Query::OtherName() &&
              Query::EventCategory() == Query::OtherCategory() &&
              Query::EventId() == Query::OtherId());

  AssociateEvents(begin, end, match);
}

void TraceAnalyzer::AssociateEvents(const Query& first,
                                    const Query& second,
                                    const Query& match) {
  DCHECK(allow_assocation_changes_)
      << "AssociateEvents not allowed after FindEvents";

  // Search for matching begin/end event pairs. When a matching end is found,
  // it is associated with the begin event.
  std::vector<TraceEvent*> begin_stack;
  for (size_t event_index = 0; event_index < raw_events_.size();
       ++event_index) {

    TraceEvent& this_event = raw_events_[event_index];

    if (second.Evaluate(this_event)) {
      // Search stack for matching begin, starting from end.
      for (int stack_index = static_cast<int>(begin_stack.size()) - 1;
           stack_index >= 0; --stack_index) {
        TraceEvent& begin_event = *begin_stack[stack_index];

        // Temporarily set other to test against the match query.
        const TraceEvent* other_backup = begin_event.other_event;
        begin_event.other_event = &this_event;
        if (match.Evaluate(begin_event)) {
          // Found a matching begin/end pair.
          // Erase the matching begin event index from the stack.
          begin_stack.erase(begin_stack.begin() + stack_index);
          break;
        }

        // Not a match, restore original other and continue.
        begin_event.other_event = other_backup;
      }
    }
    // Even if this_event is a |second| event that has matched an earlier
    // |first| event, it can still also be a |first| event and be associated
    // with a later |second| event.
    if (first.Evaluate(this_event)) {
      begin_stack.push_back(&this_event);
    }
  }
}

void TraceAnalyzer::MergeAssociatedEventArgs() {
  for (size_t i = 0; i < raw_events_.size(); ++i) {
    // Merge all associated events with the first event.
    const TraceEvent* other = raw_events_[i].other_event;
    // Avoid looping by keeping set of encountered TraceEvents.
    std::set<const TraceEvent*> encounters;
    encounters.insert(&raw_events_[i]);
    while (other && encounters.find(other) == encounters.end()) {
      encounters.insert(other);
      raw_events_[i].arg_numbers.insert(
          other->arg_numbers.begin(),
          other->arg_numbers.end());
      raw_events_[i].arg_strings.insert(
          other->arg_strings.begin(),
          other->arg_strings.end());
      other = other->other_event;
    }
  }
}

size_t TraceAnalyzer::FindEvents(const Query& query, TraceEventVector* output) {
  allow_assocation_changes_ = false;
  output->clear();
  return FindMatchingEvents(
      raw_events_, query, output, ignore_metadata_events_);
}

const TraceEvent* TraceAnalyzer::FindFirstOf(const Query& query) {
  TraceEventVector output;
  if (FindEvents(query, &output) > 0)
    return output.front();
  return NULL;
}

const TraceEvent* TraceAnalyzer::FindLastOf(const Query& query) {
  TraceEventVector output;
  if (FindEvents(query, &output) > 0)
    return output.back();
  return NULL;
}

const std::string& TraceAnalyzer::GetThreadName(
    const TraceEvent::ProcessThreadID& thread) {
  // If thread is not found, just add and return empty string.
  return thread_names_[thread];
}

void TraceAnalyzer::ParseMetadata() {
  for (size_t i = 0; i < raw_events_.size(); ++i) {
    TraceEvent& this_event = raw_events_[i];
    // Check for thread name metadata.
    if (this_event.phase != TRACE_EVENT_PHASE_METADATA ||
        this_event.name != "thread_name")
      continue;
    std::map<std::string, std::string>::const_iterator string_it =
        this_event.arg_strings.find("name");
    if (string_it != this_event.arg_strings.end())
      thread_names_[this_event.thread] = string_it->second;
  }
}

// TraceEventVector utility functions.

bool GetRateStats(const TraceEventVector& events,
                  RateStats* stats,
                  const RateStatsOptions* options) {
  DCHECK(stats);
  // Need at least 3 events to calculate rate stats.
  const size_t kMinEvents = 3;
  if (events.size() < kMinEvents) {
    LOG(ERROR) << "Not enough events: " << events.size();
    return false;
  }

  std::vector<double> deltas;
  size_t num_deltas = events.size() - 1;
  for (size_t i = 0; i < num_deltas; ++i) {
    double delta = events.at(i + 1)->timestamp - events.at(i)->timestamp;
    if (delta < 0.0) {
      LOG(ERROR) << "Events are out of order";
      return false;
    }
    deltas.push_back(delta);
  }

  std::sort(deltas.begin(), deltas.end());

  if (options) {
    if (options->trim_min + options->trim_max > events.size() - kMinEvents) {
      LOG(ERROR) << "Attempt to trim too many events";
      return false;
    }
    deltas.erase(deltas.begin(), deltas.begin() + options->trim_min);
    deltas.erase(deltas.end() - options->trim_max, deltas.end());
  }

  num_deltas = deltas.size();
  double delta_sum = 0.0;
  for (size_t i = 0; i < num_deltas; ++i)
    delta_sum += deltas[i];

  stats->min_us = *std::min_element(deltas.begin(), deltas.end());
  stats->max_us = *std::max_element(deltas.begin(), deltas.end());
  stats->mean_us = delta_sum / static_cast<double>(num_deltas);

  double sum_mean_offsets_squared = 0.0;
  for (size_t i = 0; i < num_deltas; ++i) {
    double offset = fabs(deltas[i] - stats->mean_us);
    sum_mean_offsets_squared += offset * offset;
  }
  stats->standard_deviation_us =
      sqrt(sum_mean_offsets_squared / static_cast<double>(num_deltas - 1));

  return true;
}

bool FindFirstOf(const TraceEventVector& events,
                 const Query& query,
                 size_t position,
                 size_t* return_index) {
  DCHECK(return_index);
  for (size_t i = position; i < events.size(); ++i) {
    if (query.Evaluate(*events[i])) {
      *return_index = i;
      return true;
    }
  }
  return false;
}

bool FindLastOf(const TraceEventVector& events,
                const Query& query,
                size_t position,
                size_t* return_index) {
  DCHECK(return_index);
  for (size_t i = std::min(position + 1, events.size()); i != 0; --i) {
    if (query.Evaluate(*events[i - 1])) {
      *return_index = i - 1;
      return true;
    }
  }
  return false;
}

bool FindClosest(const TraceEventVector& events,
                 const Query& query,
                 size_t position,
                 size_t* return_closest,
                 size_t* return_second_closest) {
  DCHECK(return_closest);
  if (events.empty() || position >= events.size())
    return false;
  size_t closest = events.size();
  size_t second_closest = events.size();
  for (size_t i = 0; i < events.size(); ++i) {
    if (!query.Evaluate(*events.at(i)))
      continue;
    if (closest == events.size()) {
      closest = i;
      continue;
    }
    if (fabs(events.at(i)->timestamp - events.at(position)->timestamp) <
        fabs(events.at(closest)->timestamp - events.at(position)->timestamp)) {
      second_closest = closest;
      closest = i;
    } else if (second_closest == events.size()) {
      second_closest = i;
    }
  }

  if (closest < events.size() &&
      (!return_second_closest || second_closest < events.size())) {
    *return_closest = closest;
    if (return_second_closest)
      *return_second_closest = second_closest;
    return true;
  }

  return false;
}

size_t CountMatches(const TraceEventVector& events,
                    const Query& query,
                    size_t begin_position,
                    size_t end_position) {
  if (begin_position >= events.size())
    return 0u;
  end_position = (end_position < events.size()) ? end_position : events.size();
  size_t count = 0u;
  for (size_t i = begin_position; i < end_position; ++i) {
    if (query.Evaluate(*events.at(i)))
      ++count;
  }
  return count;
}

}  // namespace trace_analyzer
