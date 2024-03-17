from flask import Flask, request, jsonify
import os
import werkzeug
import board_recognition as br

app = Flask(__name__)

@app.route('/upload', methods=["POST"])
def upload():
    if(request.method == "POST"):
        imagefile = request.files['image']
        filename = werkzeug.utils.secure_filename(imagefile.filename)
        filepath = os.path.join("./uploadedimages/", filename)
        imagefile.save(filepath)

        result = br.getfen(filename, "./uploadedimages")
        os.remove(filepath)

        return jsonify({"message": result})

if __name__ == "__main__":
    app.run(debug=True, port=4000)

# ngrok http --host-header=rewrite localhost:4000