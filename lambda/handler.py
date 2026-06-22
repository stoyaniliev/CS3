"""Innovatech employee API (Lambda, DynamoDB-backed).

Routes (via API Gateway HTTP API):
  GET    /employees          -> list all
  GET    /employees/{id}     -> get one
  POST   /employees          -> onboard (create); id auto-generated if omitted
  PATCH  /employees/{id}     -> update fields (e.g. {"status":"offboarded"})
  DELETE /employees/{id}     -> hard delete
"""
import json
import os
import uuid
import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def _resp(code, body):
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    emp_id = (event.get("pathParameters") or {}).get("id")
    try:
        data = json.loads(event.get("body") or "{}")
    except (ValueError, TypeError):
        data = {}

    try:
        if method == "GET" and emp_id:
            item = table.get_item(Key={"id": emp_id}).get("Item")
            return _resp(200, item) if item else _resp(404, {"error": "not found"})

        if method == "GET":
            return _resp(200, table.scan().get("Items", []))

        if method == "POST":  # onboard
            required = ["name", "email", "department", "role"]
            missing = [k for k in required if k not in data]
            if missing:
                return _resp(400, {"error": "missing fields", "missing": missing})
            item = {
                "id": str(data.get("id") or uuid.uuid4()),
                "name": data["name"],
                "email": data["email"],
                "department": data["department"],
                "role": data["role"],
                "status": data.get("status", "active"),
            }
            table.put_item(Item=item)
            return _resp(201, item)

        if method == "PATCH" and emp_id:  # e.g. offboard
            if not data:
                return _resp(400, {"error": "no fields to update"})
            expr = "SET " + ", ".join(f"#{k} = :{k}" for k in data)
            names = {f"#{k}": k for k in data}
            values = {f":{k}": v for k, v in data.items()}
            table.update_item(
                Key={"id": emp_id},
                UpdateExpression=expr,
                ExpressionAttributeNames=names,
                ExpressionAttributeValues=values,
            )
            return _resp(200, table.get_item(Key={"id": emp_id}).get("Item"))

        if method == "DELETE" and emp_id:
            table.delete_item(Key={"id": emp_id})
            return _resp(200, {"deleted": emp_id})

        return _resp(405, {"error": "method not allowed"})
    except Exception as exc:  # noqa: BLE001
        return _resp(500, {"error": str(exc)})
