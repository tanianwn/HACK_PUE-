from flask import Flask, request, jsonify
import os
import google.generativeai as genai

# --- Configuración de API ---
API_KEY = os.getenv("API_KEY")
if not API_KEY:
    raise RuntimeError("No encontré la API_KEY en el entorno. Ejecuta: export API_KEY='TU_API_KEY'")

try:
    genai.configure(api_key=API_KEY)
    configured = True
except Exception as e:
    print("[Aviso] genai.configure no está disponible, usando asignación directa de api_key. Detalle:", e)
    configured = False

if not configured:
    genai.api_key = API_KEY

# --- Modelo Gemini ---
model = genai.GenerativeModel("gemini-1.5-flash")

# --- Cargar base de datos (.txt) ---
with open("ceneval_preguntas.txt", "r", encoding="utf-8") as f:
    guia = f.read()

# --- Funciones de procesamiento ---
def split_text(text, chunk_size=500):
    return [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]

fragments = split_text(guia, chunk_size=500)

def search_fragments(question, fragments):
    keywords = question.lower().split()
    results = []
    for f in fragments:
        f_lower = f.lower()
        if any(word in f_lower for word in keywords):
            results.append(f)
    return results if results else fragments

def generar_respuesta(question):
    relevant_fragments = search_fragments(question, fragments)
    context = "\n".join(relevant_fragments[:3])  # máximo 3 fragmentos
    prompt = (
        f"Eres un tutor especializado en CENEVAL. "
        f"Usa solo la información de este contexto para responder:\n{context}\n\n"
        f"Pregunta del estudiante: {question}\n"
        f"Da la respuesta paso a paso, clara y detallada y no tan extensa."
        f"En caso de no tener la respuesta que el estudiante busca, indicar que pregunte al chat bot general de la app"
    )
    resp = model.generate_content(prompt)
    # Obtener texto
    try:
        return resp.text
    except Exception:
        try:
            return resp.candidates[0].content.parts[0].text
        except Exception as e:
            return f"[Error al generar respuesta]: {e}"

# --- Flask API ---
app = Flask(__name__)

@app.route("/preguntar", methods=["POST"])
def preguntar():
    data = request.json
    question = data.get("pregunta")
    if not question:
        return jsonify({"error": "No se envió ninguna pregunta"}), 400

    respuesta = generar_respuesta(question)
    return jsonify({"respuesta": respuesta})

if __name__ == "__main__":
    print("Servidor Flask corriendo en http://0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000)




