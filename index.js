console.log('Loading function')

exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2))

  let operation = event.operation
  let tableName = event.tableName

  const response = {
    statusCode: 200,
    body: {
      operation,
      table_name: tableName,
      content: 'Hello from Lambda!',
    },
  }
  
  return response
}