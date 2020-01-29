project_name = lambda-api-gateway
role_name = $(project_name)-role
function_name = $(project_name)-function

init:
	@echo $(project_name) "- my first Lambda function with API Gateway"

create-role:
	aws iam create-role --role-name $(role_name) --assume-role-policy-document file://trust-policy.json

delete-role:
	aws iam delete-role --role-name $(role_name)

create-package:
	zip function.zip index.js

account-identity:
	aws sts get-caller-identity

create-function: create-package account-identity
	@read -p "Copy and past your number account: " accountId; \
	aws lambda create-function --function-name $(function_name) \
--zip-file fileb://function.zip --handler index.handler --runtime nodejs12.x \
--role arn:aws:iam::$$accountId:role/$(role_name)

update-function: create-package account-identity
	@read -p "Copy and past your number account: " accountId; \
	aws lambda update-function-code --function-name $(function_name) \
--zip-file fileb://function.zip

invoke-function:
	aws lambda invoke --function-name $(function_name) \
--payload fileb://input.json output.json
	@echo "Response: \n"
	@cat output.json
	@echo "\n"
