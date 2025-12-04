# Copilot Instructions for tf-monorepo

## Project Overview
This is a Terraform monorepo containing reusable Terraform modules for organizational infrastructure management.

## Technology Stack
- **Terraform**: Infrastructure as Code tool
- **HCL (HashiCorp Configuration Language)**: Primary language for Terraform configurations
- **Git**: Version control system

## Project Structure
```
tf-monorepo/
├── .github/              # GitHub configuration and workflows
├── modules/              # Terraform modules directory (when created)
│   ├── module-name/      # Individual module
│   │   ├── main.tf       # Main configuration
│   │   ├── variables.tf  # Input variables
│   │   ├── outputs.tf    # Output values
│   │   └── README.md     # Module documentation
├── .gitignore            # Git ignore patterns for Terraform
├── LICENSE               # License file
└── README.md             # Repository documentation
```

## Commands and Workflows

### Terraform Commands
```bash
# Initialize Terraform (download providers and modules)
terraform init

# Validate Terraform configuration
terraform validate

# Format Terraform files to canonical format
terraform fmt -recursive

# Check formatting without making changes
terraform fmt -check -recursive

# Create execution plan
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

### Git Workflow
```bash
# Check status
git status

# Stage changes
git add .

# Commit changes
git commit -m "descriptive message"

# Push changes
git push
```

## Code Style Guidelines

### Terraform Best Practices
1. **File Organization**: Each module should have separate files:
   - `main.tf`: Main resource definitions
   - `variables.tf`: Input variable declarations
   - `outputs.tf`: Output value declarations
   - `versions.tf`: Provider version constraints
   - `README.md`: Module documentation

2. **Naming Conventions**:
   - Use lowercase with underscores for resource names: `resource_name`
   - Use descriptive names that indicate the resource purpose
   - Prefix resources with module name when appropriate

3. **Variable Declarations**:
   - Always include descriptions for variables
   - Set appropriate types (string, number, bool, list, map, object)
   - Provide default values when sensible
   - Use validation rules when appropriate

4. **Documentation**:
   - Document all input variables in README
   - Document all outputs in README
   - Include usage examples in module README
   - Add inline comments for complex logic

5. **Formatting**:
   - Always run `terraform fmt` before committing
   - Use consistent indentation (2 spaces)
   - Group related resources together

### Example Variable Declaration
```hcl
variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring for resources"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
```

### Example Resource Definition
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "${var.project_name}-${var.environment}-bucket"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-bucket"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
```

## Boundaries and Constraints

### DO:
- Follow Terraform best practices and HCL style guide
- Always format code with `terraform fmt` before committing
- Validate configurations with `terraform validate`
- Document all modules with comprehensive README files
- Use semantic versioning for module releases
- Keep modules focused and composable
- Use data sources to reference existing resources
- Implement proper error handling and validation
- Add meaningful comments for complex logic
- Test modules in isolation before integration

### DO NOT:
- Hardcode sensitive values (credentials, API keys, secrets)
- Include `.tfstate` files in version control (already in .gitignore)
- Include `.terraform` directories in version control (already in .gitignore)
- Include `*.tfvars` files with sensitive data (already in .gitignore)
- Modify resources created by other modules without understanding dependencies
- Create circular dependencies between modules
- Use deprecated Terraform features or syntax
- Commit unformatted code
- Skip validation before committing

### Security Considerations:
- Never commit AWS access keys, passwords, or tokens
- Use Terraform Cloud or backend encryption for state files
- Use variables for sensitive values
- Follow principle of least privilege for IAM policies
- Use secure defaults for resources
- Validate input data to prevent injection attacks

## Module Development Workflow

1. **Planning**:
   - Understand the infrastructure requirement
   - Design the module interface (inputs/outputs)
   - Plan resource organization

2. **Development**:
   - Create module directory structure
   - Write resource definitions in `main.tf`
   - Define variables in `variables.tf`
   - Define outputs in `outputs.tf`
   - Add provider constraints in `versions.tf`

3. **Documentation**:
   - Write comprehensive README with:
     - Module description
     - Usage examples
     - Input variable documentation
     - Output documentation
     - Requirements and dependencies

4. **Testing**:
   - Run `terraform fmt -recursive`
   - Run `terraform validate`
   - Test with example configurations
   - Verify outputs are correct

5. **Review**:
   - Ensure security best practices
   - Check for hardcoded values
   - Verify documentation is complete
   - Confirm code follows style guidelines

## Common Tasks

### Creating a New Module
```bash
# Create module directory
mkdir -p modules/my-module

# Create standard files
touch modules/my-module/main.tf
touch modules/my-module/variables.tf
touch modules/my-module/outputs.tf
touch modules/my-module/versions.tf
touch modules/my-module/README.md
```

### Updating Documentation
When modifying a module, always update:
- README.md with new variables/outputs
- Inline comments for complex changes
- Usage examples if interface changed

## Additional Resources
- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [HCL Configuration Syntax](https://www.terraform.io/docs/language/syntax/configuration.html)
