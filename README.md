# Terraform ECS

- Create a backend bucket for terraform state with aws cli
```bash
aws s3api create-bucket --bucket terraform-cloudgeeks --region us-east-1
```

- Enable versioning on the bucket
```bash
aws s3api put-bucket-versioning --bucket terraform-cloudgeeks --versioning-configuration Status=Enabled
```

- List the bucket
```bash
aws s3 ls
```

- Aws ACM certificate
```bash
aws acm request-certificate --domain-name '*.saqlainmushtaq.com' --validation-method DNS --subject-alternative-names saqlainmushtaq.com
```

- Note: Above command will provide the ACM certificate ARN, which will be used in the terraform code, but must add CNAME record in the DNS to validate the certificate.

### Create a namespace in aws cloud map

- Aws Cli list VPC Name & ID
```bash
aws ec2 describe-vpcs --query 'Vpcs[*].{Name:Tags[?Key==`Name`]|[0].Value, VpcId:VpcId}' --output table
```
- Create a namespace in aws cloud map
```bash
aws servicediscovery create-private-dns-namespace --name saqlainmushtaq.com --vpc vpc-0ca3113bbd47d9eb0 --region us-east-1
```

- List the namespace
```bash
aws servicediscovery list-namespaces
```