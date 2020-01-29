project_name = lambda-api-gateway
role_name = $(project_name)-role
function_name = $(project_name)-function
api_name = $(project_name)-rest-api
aws_region = us-east-2
statement_id = $(project_name)-statement

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

create-api:
	aws apigateway create-rest-api --name $(api_name)
	@echo "\nCOPY YOUR REST API ID!"

delete-api:
	@read -p "Insert your rest api id: " apiId; \
	aws apigateway delete-rest-api --rest-api-id $$apiId

get-resources-api:
	@read -p "Insert your rest api id: " apiId; \
	aws apigateway get-resources --rest-api-id $$apiId

create-resource-api: get-resources-api
	@read -p "Insert your rest api id: " apiId; \
	read -p "Insert your parent id: " parentId; \
	aws apigateway create-resource --path-part $(api_name) \
--rest-api-id $$apiId --parent-id $$parentId

create-method-api: get-resources-api
	@read -p "Insert your rest api id: " apiId; \
	read -p "Insert your parent id: " parentId; \
	read -p "Insert the method: " method; \
	aws apigateway put-method --rest-api-id $$apiId --resource-id $$parentId \
--http-method $$method --authorization-type NONE

create-integration-method-api: account-identity get-resources-api
	@read -p "Copy and past your number account: " accountId; \
	read -p "Insert your rest api id: " apiId; \
	read -p "Insert your parent id: " parentId; \
	read -p "Insert the method: " method; \
	aws apigateway put-integration --rest-api-id $$apiId \
--resource-id $$parentId --http-method $$method \
--type AWS --integration-http-method $$method \
--uri arn:aws:apigateway:$(aws_region):lambda:path/2015-03-31/functions/arn:aws:lambda:$(aws_region):$$accountId:function:$(function_name)/invocations

setup-method-response-api: get-resources-api
	@read -p "Insert your rest api id: " apiId; \
	read -p "Insert your parent id: " parentId; \
	read -p "Insert the method: " method; \
	aws apigateway put-method-response --rest-api-id $$apiId \
--resource-id $$parentId --http-method $$method \
--status-code 200 --response-models application/json=Empty

setup-method-response-lambda: get-resources-api
	@read -p "Insert your rest api id: " apiId; \
	read -p "Insert your parent id: " parentId; \
	read -p "Insert the method: " method; \
	aws apigateway put-integration-response --rest-api-id $$apiId \
--resource-id $$parentId --http-method $$method \
--status-code 200 --response-templates application/json=""

create-deployment-api:
	@read -p "Insert your rest api id: " apiId; \
	read -p "Insert the stage name: " stageName; \
	aws apigateway create-deployment --rest-api-id $$apiId \
--stage-name $$stageName

setup-permission-lambda: account-identity
	@read -p "Copy and past your number account: " accountId; \
	read -p "Insert your rest api id: " apiId; \
	read -p "Insert the stage name: " stageName; \
	read -p "Insert the method: " method; \
	aws lambda add-permission --function-name $(function_name) \
--statement-id $(statement_id) --action lambda:InvokeFunction \
--principal apigateway.amazonaws.com \
--source-arn "arn:aws:execute-api:$(aws_region):$$accountId:$$apiId/$$stageName/$$method/$(api_name)"
