// 📂 functions/index.js
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { RekognitionClient, DetectModerationLabelsCommand } = require("@aws-sdk/client-rekognition");

admin.initializeApp();

exports.analizarFoto = functions
  .region("southamerica-east1") // El celador sigue en Brasil
  .runWith({
    secrets: ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"],
    memory: "512MB"
  })
  .storage.object().onFinalize(async (object) => {

    console.log("🚀 ROBOT ACTIVADO. Archivo detectado:", object.name);

    const filePath = object.name;
    const contentType = object.contentType;

    // 1. Si no es imagen, lo ignoramos de inmediato
    if (!contentType || !contentType.startsWith("image/")) {
      return null;
    }

    // 2. 🛡️ ESCUDO DE FORMATO: Amazon solo lee JPG y PNG.
    // Rechazamos webp, gif, heic, etc., para no colapsar ni gastar saldo.
    if (!contentType.includes("jpeg") && !contentType.includes("png")) {
      console.log(`⚠️ ALERTA FORMATO: El archivo ${filePath} es un formato no soportado (${contentType}). Procediendo a eliminar...`);

      // ✅ Línea de ejecución activada. El robot DESTRUYE formatos raros.
      await admin.storage().bucket(object.bucket).file(filePath).delete();
      console.log(`🗑️ Archivo de formato inválido eliminado exitosamente.`);

      return null;
    }

    // 3. Conectamos el cerebro directo a la sede central de EE. UU.
    const rekognition = new RekognitionClient({
      region: "us-east-1",
      credentials: {
        accessKeyId: (process.env.AWS_ACCESS_KEY_ID || "").trim(),
        secretAccessKey: (process.env.AWS_SECRET_ACCESS_KEY || "").trim(),
      },
    });

    const bucket = admin.storage().bucket(object.bucket);
    const file = bucket.file(filePath);

    try {
      console.log("📥 Paso 2: Descargando imagen para inspección...");
      const [buffer] = await file.download();

      const command = new DetectModerationLabelsCommand({
        Image: { Bytes: buffer },
        MinConfidence: 55,
      });

      console.log("📡 Paso 3: Consultando a la Inteligencia Artificial de Amazon (Virginia)...");
      const response = await rekognition.send(command);
      const labels = response.ModerationLabels;

      console.log("🏷️ Etiquetas encontradas por Amazon:", JSON.stringify(labels));

      // 🛡️ ESCUDO TOTAL: Desnudos + Violencia (Actualizada) + Gore + Odio
      const esInapropiada = labels.some(label =>
        // Bloque 1: Desnudos y Sexo
        label.Name === "Explicit Nudity" ||
        label.Name === "Nudity" ||
        label.Name === "Suggestive" ||
        label.Name === "Sexual Activity" ||
        label.ParentName === "Explicit Nudity" ||
        label.ParentName === "Nudity" ||

        // Bloque 2: Violencia, Muerte y Gore (Con el diccionario actualizado de AWS)
        label.Name === "Corpse" ||
        label.Name === "Graphic Violence Or Gore" ||
        label.Name === "Physical Violence" ||
        label.Name === "Weapon Violence" ||
        label.Name === "Violence" ||
        label.Name === "Graphic Violence" ||
        label.Name === "Blood & Gore" ||
        label.ParentName === "Violence" ||

        // Bloque 3: Símbolos de Odio y Extremismo
        label.Name === "Hate Symbols"
      );

      if (esInapropiada) {
        console.log(`🚨 ¡ESCÁNDALO/VIOLENCIA DETECTADA! Borrando archivo prohibido: ${filePath}`);
        await file.delete();
        console.log(`🗑️ ELIMINACIÓN EXITOSA. Matchy está a salvo.`);
      } else {
        console.log(`🟢 FOTO LIMPIA: El usuario puede usar ${filePath}`);
      }

    } catch (error) {
      console.error("❌ ERROR CRÍTICO EN EL PROCESO:", error.message);
      console.error("🔍 Detalle oculto del error de Amazon:", JSON.stringify(error, null, 2));
    }
    return null;
  });