locals {
  users_usernames     = [for user in var.users : user.username]                # user.tfvars から username を取得
  org_owner_usernames = setintersection(local.users_usernames, var.org_owners) # Organization owner の username
}

# Organization owner
# `depends_on` を設定することで module "security" が実行された後に処理されるようにしています
resource "github_membership" "org_owner" {
  for_each = toset(local.org_owner_usernames)

  username = each.value
  role     = "admin"

  depends_on = [
    module.security
  ]
}

# リポジトリの作成 Terraform 操作するリポジトリの作成（ terraform-operations ）
# `terraform-operations` は作成したリポジトリ名に変更してください。
# `terraform_operations` はリソース名になります。リポジトリ名と合わせた方が良いですが、`-`が使えないので`_`に置き換えてください。
# 各項目については公式ドキュメントを参考に変更してください。
# 公式ドキュメント → https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository
resource "github_repository" "terraform_operations" {
  name                   = "terraform-operations"
  description            = "Organization 配下のリソースを管理する Terraform ソースの置き場所"
  visibility             = "public"
  allow_auto_merge       = false
  allow_merge_commit     = true
  allow_rebase_merge     = true
  allow_squash_merge     = true
  allow_update_branch    = false
  delete_branch_on_merge = true
  has_discussions        = false
  has_issues             = true
  has_projects           = false
  has_wiki               = false
  homepage_url           = null
  is_template            = false
  vulnerability_alerts   = true
}

# tfstate ファイルを管理するリポジトリの作成（ terraform-state-files ）
# `terraform-state-files`は作成したリポジトリ名に変更してください。
# `terraform_state_files`はリソース名になります。リポジトリ名と合わせた方が良いですが、`-`が使えないので`_`に置き換えてください。
resource "github_repository" "terraform_state_files" {
  name                   = "terraform-state-files"
  description            = "リポジトリ `github-operations` の GitHub Actions から利用される Terraform state file を保管する"
  visibility             = "private"
  allow_auto_merge       = false
  allow_merge_commit     = true
  allow_rebase_merge     = true
  allow_squash_merge     = true
  allow_update_branch    = false
  delete_branch_on_merge = false
  has_discussions        = false
  has_issues             = false
  has_projects           = false
  has_wiki               = false
  homepage_url           = null
  is_template            = false
  vulnerability_alerts   = true
}

# ユーザーの GitHub Username と GitHub ID のチェック
module "security" {
  source = "./module/security"

  users_defined = var.users
}

# tfstate ファイル
## Terraform が管理しているリソースの現在の状態を記録したファイル
variable "pem_content" {
  description = "The content of the PEM file"
  type        = string
}

# Organization owner として任命するユーザー名を受け取るための変数
variable "org_owners" {
  description = "List of users to assign the 'owner' role for the organization"
  type        = list(string)
}

# ユーザー情報を users.tfvars から受け取るための変数
variable "users" {
  description = "List of users"
  type = list(object({
    username = string
    id       = string
  }))
}
