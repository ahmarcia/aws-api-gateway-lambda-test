project_name = lambda-api-gateway
role_name = $(project_name)-role

init:
	@echo $(project_name) "- my first Lambda function with API Gateway"

create-role:
	aws iam create-role --role-name $(role_name) --assume-role-policy-document file://trust-policy.json

delete-role:
	aws iam delete-role --role-name $(role_name)
