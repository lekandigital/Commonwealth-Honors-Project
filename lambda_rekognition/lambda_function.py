import json
import boto3
import io
from urllib.request import urlopen 
import base64

def lambda_handler(event, context):
    
    client = boto3.client("rekognition")
    
    base64_string = event['imageBase64']

    imgdata = base64.b64decode(base64_string)
    f = io.BytesIO(imgdata)
    
    response = client.detect_faces(Image = {"Bytes": f.read()},  Attributes=['ALL'])
    
    emotionResponse = None
    
    try:
        emotionResponse = response['FaceDetails'][0]
    except: 
        pass
    
    print(type(emotionResponse))
    
    return {
        'data':emotionResponse
    }
