//
//
// Copyright 2023 gRPC authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//

#ifndef GRPC_GRPC_AUDIT_LOGGING_H
#define GRPC_GRPC_AUDIT_LOGGING_H

#include <grpc/support/json.h>
#include <grpc/support/port_platform.h>

#include <memory>
#include <string>

#include "absl/status/statusor.h"
#include "absl/strings/string_view.h"

namespace grpc_core {

class EvaluateArgs;

namespace experimental {

// The class containing the context for an audited RPC.
class AuditContext {
 public:
  AuditContext(absl::string_view rpc_method, absl::string_view principal,
               absl::string_view policy_name, absl::string_view matched_rule,
               bool authorized, absl::string_view client_ip, int client_port,
               absl::string_view certificate_subject,
               absl::string_view certificate_common_name,
               std::vector<absl::string_view> certificate_uri_sans,
               std::vector<absl::string_view> certificate_dns_sans,
               const EvaluateArgs* eval_args)
      : rpc_method_(rpc_method),
        principal_(principal),
        policy_name_(policy_name),
        matched_rule_(matched_rule),
        authorized_(authorized),
        client_ip_(client_ip),
        client_port_(client_port),
        certificate_subject_(certificate_subject),
        certificate_common_name_(certificate_common_name),
        certificate_uri_sans_(std::move(certificate_uri_sans)),
        certificate_dns_sans_(std::move(certificate_dns_sans)),
        eval_args_(eval_args) {}

  absl::string_view rpc_method() const { return rpc_method_; }
  absl::string_view principal() const { return principal_; }
  absl::string_view policy_name() const { return policy_name_; }
  absl::string_view matched_rule() const { return matched_rule_; }
  bool authorized() const { return authorized_; }
  absl::string_view client_ip() const { return client_ip_; }
  int client_port() const { return client_port_; }
  absl::string_view certificate_subject() const { return certificate_subject_; }
  absl::string_view certificate_common_name() const {
    return certificate_common_name_;
  }
  std::vector<absl::string_view> certificate_uri_sans() const {
    return certificate_uri_sans_;
  }
  std::vector<absl::string_view> certificate_dns_sans() const {
    return certificate_dns_sans_;
  }
  std::optional<absl::string_view> GetHeaderValue(
      absl::string_view key, std::string* concatenated_value) const;

 private:
  absl::string_view rpc_method_;
  absl::string_view principal_;
  absl::string_view policy_name_;
  absl::string_view matched_rule_;
  bool authorized_;
  absl::string_view client_ip_;
  int client_port_;
  absl::string_view certificate_subject_;
  absl::string_view certificate_common_name_;
  std::vector<absl::string_view> certificate_uri_sans_;
  std::vector<absl::string_view> certificate_dns_sans_;
  const EvaluateArgs* eval_args_;
};

// This base class for audit logger implementations.
class AuditLogger {
 public:
  virtual ~AuditLogger() = default;
  virtual absl::string_view name() const = 0;
  virtual void Log(const AuditContext& audit_context) = 0;
};

// This is the base class for audit logger factory implementations.
class AuditLoggerFactory {
 public:
  class Config {
   public:
    virtual ~Config() = default;
    virtual absl::string_view name() const = 0;
    virtual std::string ToString() const = 0;
  };

  virtual ~AuditLoggerFactory() = default;
  virtual absl::string_view name() const = 0;

  virtual absl::StatusOr<std::unique_ptr<Config>> ParseAuditLoggerConfig(
      const Json& json) = 0;

  virtual std::unique_ptr<AuditLogger> CreateAuditLogger(
      std::unique_ptr<AuditLoggerFactory::Config>) = 0;
};

// Registers an audit logger factory. This should only be called during
// initialization.
void RegisterAuditLoggerFactory(std::unique_ptr<AuditLoggerFactory> factory);

}  // namespace experimental
}  // namespace grpc_core

#endif  // GRPC_GRPC_AUDIT_LOGGING_H
