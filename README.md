# Terraform ECS Service Discovery

- https://www.youtube.com/watch?v=bcjqcv9zLwU&t=344s
  
- https://github.com/quickbooks2018/ecs-service-discovery
  
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

##### SSM Secure String Parameter with aws cli
```bash
aws ssm put-parameter --name "pythonapp_secret_1" --value "your_secure_value" --type SecureString
```
```bash
aws ssm put-parameter --name "pythonapp_secret_2" --value "your_secure_value" --type SecureString
```

- TroubleShooting https://stackoverflow.com/questions/53370256/aws-creation-failed-service-already-exists-service-awsservicediscovery-stat
```bash
aws servicediscovery list-services --region us-east-1
```
```bash
aws servicediscovery delete-service --id srv-i36tuwrjlbrr4ogl
```

- Create a service in aws cloud map (Note: These commands are not required for aws ecs service connect)
```bash
aws servicediscovery create-service --name redis --namespace-id ns-b5dgvb5y7cbssha5 --dns-config 'NamespaceId=ns-b5dgvb5y7cbssha5,DnsRecords=[{Type=A,TTL=10}]'
aws servicediscovery create-service --name pythonapp --namespace-id ns-b5dgvb5y7cbssha5 --dns-config 'NamespaceId=ns-b5dgvb5y7cbssha5,DnsRecords=[{Type=A,TTL=10}]'
```

- Create a service in aws cloud map with different format (Note: These commands are not required for aws ecs service connect)
```bash
aws servicediscovery create-service --name redis --namespace-id ns-b5dgvb5y7cbssha5 --dns-config '{"NamespaceId": "ns-b5dgvb5y7cbssha5", "DnsRecords": [{"Type": "A", "TTL": 10}]}'
aws servicediscovery create-service --name pythonapp --namespace-id ns-b5dgvb5y7cbssha5 --dns-config '{"NamespaceId": "ns-b5dgvb5y7cbssha5", "DnsRecords": [{"Type": "A", "TTL": 10}]}'
```