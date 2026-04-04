// 📂 functions/index.js
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { RekognitionClient, DetectModerationLabelsCommand } = require("@aws-sdk/client-rekognition");

admin.initializeApp();

exports.analizarFoto = functions
  .region("southamerica-east1") // Sede en Brasil
  .runWith({
    secrets: ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"],
    memory: "512MB"
  })
  .storage.object().onFinalize(async (object) => {

    console.log("🚀 ROBOT ACTIVADO. Archivo detectado:", object.name);

    const filePath = object.name;
    const contentType = object.contentType;

    if (!contentType || !contentType.startsWith("image/")) return null;

    if (!contentType.includes("jpeg") && !contentType.includes("png")) {
      console.log(`⚠️ FORMATO INVÁLIDO (${contentType}). Eliminando...`);
      await admin.storage().bucket(object.bucket).file(filePath).delete();
      return null;
    }

    // 🔍 EXTRAER EL ID DEL USUARIO DESDE LA RUTA (Ej: users/{uid}/photos/photo.png)
    const pathParts = filePath.split("/");
    if (pathParts.length < 3 || pathParts[0] !== "users") {
       console.log("Ruta no estándar (no pertenece a un perfil de usuario). Ignorando BD.");
       return null;
    }
    const uid = pathParts[1];
    const db = admin.firestore();

    const rekognition = new RekognitionClient({
      region: "us-east-1",
      credentials: {
        accessKeyId: (process.env.AWS_ACCESS_KEY_ID || "").trim(),
        secretAccessKey: (process.env.AWS_SECRET_ACCESS_KEY || "").trim(),
      },
    });

    const file = admin.storage().bucket(object.bucket).file(filePath);

    try {
      const [buffer] = await file.download();

      const command = new DetectModerationLabelsCommand({
        Image: { Bytes: buffer },
        MinConfidence: 55,
      });

      const response = await rekognition.send(command);
      const labels = response.ModerationLabels;

      console.log("🏷️ Etiquetas detectadas:", JSON.stringify(labels));

      const esInapropiada = labels.some(label =>
        label.Name === "Explicit Nudity" ||
        label.Name === "Nudity" ||
        label.Name === "Suggestive" ||
        label.Name === "Sexual Activity" ||
        label.ParentName === "Explicit Nudity" ||
        label.ParentName === "Nudity" ||
        label.Name === "Corpse" ||
        label.Name === "Graphic Violence Or Gore" ||
        label.Name === "Physical Violence" ||
        label.Name === "Weapon Violence" ||
        label.Name === "Violence" ||
        label.Name === "Graphic Violence" ||
        label.Name === "Blood & Gore" ||
        label.ParentName === "Violence" ||
        label.Name === "Hate Symbols"
      );

      if (esInapropiada) {
        console.log(`🚨 INFRACCIÓN DETECTADA. Borrando archivo de Storage...`);
        await file.delete();

        // Determinar el motivo exacto para la burbuja en la app
        let motivoStr = "Contenido no permitido por las normas de comunidad.";
        if (labels.some(l => l.Name.includes("Nudity") || l.Name.includes("Suggestive"))) {
            motivoStr = "Desnudez o contenido sugerente detectado.";
        } else if (labels.some(l => l.Name.includes("Violence") || l.Name.includes("Gore"))) {
            motivoStr = "Violencia, armas o material sensible detectado.";
        } else if (labels.some(l => l.Name === "Hate Symbols")) {
            motivoStr = "Símbolos de odio o extremismo detectados.";
        }

        // 📝 ENVIAR BILLETE DE INFRACCIÓN A LA BASE DE DATOS
        await db.collection("users").doc(uid).update({
          foto_estado: "rechazada",
          foto_motivo: motivoStr
        });

      } else {
        console.log(`🟢 FOTO LIMPIA. Aprobando en la Base de Datos...`);

        // 📝 ENVIAR SELLO DE APROBACIÓN A LA BASE DE DATOS
        await db.collection("users").doc(uid).update({
          foto_estado: "aprobada"
        });
      }

    } catch (error) {
      console.error("❌ ERROR CRÍTICO:", error.message);
    }
    return null;
  });

// ============================================================================
// 🔥 NUEVO MÓDULO: CHECK AZUL (VERIFICACIÓN BIOMÉTRICA)
// ============================================================================
const { CompareFacesCommand } = require("@aws-sdk/client-rekognition");
const axios = require("axios");

exports.verificarIdentidad = functions
  .region("southamerica-east1") // Mantenemos la misma región por eficiencia
  .runWith({
    secrets: ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"],
    memory: "512MB"
  })
  .https.onCall(async (data, context) => {
    // 1. Barrera de Seguridad
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Acceso denegado. Usuario no autenticado.");
    }

    const uid = context.auth.uid;
    const selfieBase64 = data.selfieBase64;

    if (!selfieBase64) {
      throw new functions.https.HttpsError("invalid-argument", "No se recibió el escaneo facial (Selfie).");
    }

    const db = admin.firestore();

    try {
      // 2. Extraer foto de perfil de Firestore
      const userRef = db.collection("users").doc(uid);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Usuario no encontrado en la matriz.");
      }

      const profilePhotoUrl = userDoc.data().profilePhotoUrl;
      if (!profilePhotoUrl) {
        throw new functions.https.HttpsError("failed-precondition", "No tienes una foto de perfil principal para comparar.");
      }

      // 3. Descargar la foto de perfil en memoria RAM (Buffer)
      const response = await axios.get(profilePhotoUrl, { responseType: "arraybuffer" });
      const profilePhotoBuffer = Buffer.from(response.data, "binary");

      // 4. Convertir la Selfie en vivo a memoria RAM (Buffer)
      const selfieBuffer = Buffer.from(selfieBase64, "base64");

      // 5. Instanciar AWS con los secretos encriptados
      const rekognition = new RekognitionClient({
        region: "us-east-1",
        credentials: {
          accessKeyId: (process.env.AWS_ACCESS_KEY_ID || "").trim(),
          secretAccessKey: (process.env.AWS_SECRET_ACCESS_KEY || "").trim(),
        },
      });

      // 6. Lanzar comando de comparación facial
      const command = new CompareFacesCommand({
        SourceImage: { Bytes: selfieBuffer },
        TargetImage: { Bytes: profilePhotoBuffer },
        SimilarityThreshold: 90.0, // Solo pasa si es 90% o más similar
      });

      const awsResponse = await rekognition.send(command);

      // 7. Evaluar el veredicto
      if (awsResponse.FaceMatches && awsResponse.FaceMatches.length > 0) {
        const similarity = awsResponse.FaceMatches[0].Similarity;

        if (similarity >= 90.0) {
          // 🟢 MATCH EXITOSO: Inyectar Check Azul en Firebase
          await userRef.update({
            isVerified: true,
            verifiedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          return {
            success: true,
            similarity: similarity,
            message: "IDENTIDAD CONFIRMADA. Bienvenido a la élite, Matchy."
          };
        }
      }

      // 🔴 MATCH FALLIDO: Catfish detectado
      return {
        success: false,
        similarity: awsResponse.FaceMatches && awsResponse.FaceMatches.length > 0 ? awsResponse.FaceMatches[0].Similarity : 0,
        message: "ACCESO DENEGADO. El rostro no coincide con tu foto de perfil."
      };

    } catch (error) {
      console.error("❌ ERROR EN BIOMETRÍA:", error.message);
      throw new functions.https.HttpsError("internal", "El motor biométrico falló: " + error.message);
    }
  });