const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const s3 = new S3Client();

exports.handler = async (event) => {
    try {
        const body = JSON.parse(event.body);
        const buffer = Buffer.from(body.image_base64, 'base64');
        const filename = `uploads/img_${Date.now()}.jpg`;

        await s3.send(new PutObjectCommand({
            Bucket: process.env.S3_BUCKET,
            Key: filename,
            Body: buffer,
            ContentType: 'image/jpeg'
        }));

        return { statusCode: 200, body: JSON.stringify({ message: "Upload success", path: filename }) };
    } catch (e) {
        return { statusCode: 500, body: JSON.stringify({ error: e.message }) };
    }
};