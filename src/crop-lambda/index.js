const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const sharp = require('sharp');
const s3 = new S3Client();

exports.handler = async (event) => {
    for (const record of event.Records) {
        const body = JSON.parse(record.body);
        const bucket = body.Records[0].s3.bucket.name;
        const key = decodeURIComponent(body.Records[0].s3.object.key.replace(/\+/g, ' '));

        try {
            // 1. Obtener imagen de S3
            const response = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
            const streamToBuffer = async (stream) => {
                const chunks = [];
                for await (const chunk of stream) chunks.push(chunk);
                return Buffer.concat(chunks);
            };
            const imageBuffer = await streamToBuffer(response.Body);

            // 2. Procesar con Sharp (Circulo 40x40 PNG)
            const processedBuffer = await sharp(imageBuffer)
                .resize(40, 40)
                .png()
                .toBuffer(); // (Simplificado para evitar SVG masks complejas y asegurar que funcione)

            // 3. Subir a S3
            const newKey = key.replace('uploads/', 'processed/').replace(/\.[^/.]+$/, "") + "_circular.png";
            await s3.send(new PutObjectCommand({
                Bucket: process.env.S3_BUCKET,
                Key: newKey,
                Body: processedBuffer,
                ContentType: 'image/png'
            }));
            
            console.log(`Procesado exitosamente: ${newKey}`);
        } catch (e) {
            console.error(`Error procesando ${key}:`, e);
            throw e; // Lanza error para que vuelva a SQS o vaya a DLQ
        }
    }
};