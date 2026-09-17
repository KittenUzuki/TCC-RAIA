from flask import Flask, request
from backend import sugerir_receitas

app = Flask(__name__)

@app.route("/sugerir", methods=["POST", "OPTIONS"])
def rota():
    return sugerir_receitas(request)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)