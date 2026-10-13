import base64
import json
import os
import re
import uuid

import boto3

s3 = boto3.client("s3")

BUCKET = os.environ["UPLOAD_BUCKET"]
MAX_BYTES = int(os.environ.get("MAX_BYTES", "5242880"))

ALLOWED_EXTENSIONS = {
    ".txt",
    ".csv",
    ".json",
    ".pdf",
    ".png",
    ".jpg",
    ".jpeg",
}


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "content-type": "application/json"
        },
        "body": json.dumps(body),
    }


def clean_filename(filename):
    filename = os.path.basename(filename)
    filename = re.sub(r"[^A-Za-z0-9._-]", "_", filename)

    if not filename or filename in {".", ".."}:
        filename = "upload.bin"

    return filename


def lambda_handler(event, context):
    try:
        query = event.get("queryStringParameters") or {}
        filename = clean_filename(query.get("filename", "upload.bin"))

        extension = os.path.splitext(filename.lower())[1]

        if extension not in ALLOWED_EXTENSIONS:
            return response(
                400,
                {
                    "error": "File type not allowed",
                    "allowed_extensions": sorted(ALLOWED_EXTENSIONS),
                },
            )

        body = event.get("body") or ""

        if event.get("isBase64Encoded"):
            data = base64.b64decode(body)
        else:
            data = body.encode("utf-8")

        if len(data) > MAX_BYTES:
            return response(
                413,
                {
                    "error": "File too large",
                    "max_bytes": MAX_BYTES,
                },
            )

        key = f"uploads/{uuid.uuid4()}-{filename}"

        s3.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=data,
        )

        print(
            json.dumps(
                {
                    "message": "Upload successful",
                    "bucket": BUCKET,
                    "key": key,
                    "size": len(data),
                }
            )
        )

        return response(
            201,
            {
                "message": "Upload successful",
                "bucket": BUCKET,
                "key": key,
                "size": len(data),
            },
        )

    except Exception as exc:
        print(f"Upload failed: {exc}")
        return response(
            500,
            {
                "error": "Internal server error"
            },
        )
