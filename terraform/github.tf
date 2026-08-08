resource "github_branch_protection" "main" {
  repository_id = var.github_repository
  pattern       = "main"

  enforce_admins = true

  required_status_checks {
    strict   = true
    contexts = ["plan"]
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
    dismiss_stale_reviews           = true
  }

  allows_force_pushes = false
  allows_deletions    = false
}