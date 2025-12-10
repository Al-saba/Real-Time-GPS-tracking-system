from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import json
import os
from datetime import datetime

app = Flask(__name__, static_url_path="", static_folder=".")
CORS(app)

SAVED_PATH_FILE = "saved_paths.json"
POINTS_FILE = "points.json"

def load_saved_paths():
    if not os.path.exists(SAVED_PATH_FILE):
        return []
    try:
        with open(SAVED_PATH_FILE, "r") as f:
            return json.load(f)
    except:
        return []

def save_saved_paths(data):
    with open(SAVED_PATH_FILE, "w") as f:
        json.dump(data, f, indent=4)

def load_points():
    """Load existing points from points.json"""
    if not os.path.exists(POINTS_FILE):
        return []
    try:
        with open(POINTS_FILE, "r") as f:
            return json.load(f)
    except:
        return []

def save_points(points):
    """Save points to points.json"""
    with open(POINTS_FILE, "w") as f:
        json.dump(points, f, indent=2)

@app.route("/")
def home():
    return app.send_static_file("index.html")

@app.route("/upload", methods=["POST"])
def upload_gps():
    """Receive GPS data from fake_generator.sh and append to points.json"""
    data = request.json
    
    # Validate incoming data
    if not data or "lat" not in data or "lon" not in data:
        return jsonify({"status": "error", "message": "Missing lat/lon"}), 400
    
    # Load existing points
    points = load_points()
    
    # Create new point entry
    new_point = {
        "t": data.get("t", datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")),
        "id": data.get("id", "device-1"),
        "lat": float(data["lat"]),
        "lon": float(data["lon"])
    }
    
    # Append new point
    points.append(new_point)
    
    # Save to file
    save_points(points)
    
    return jsonify({"status": "ok", "point": new_point})

@app.route("/saved_paths", methods=["GET"])
def get_saved_paths():
    return jsonify(load_saved_paths())

@app.route("/save_path", methods=["POST"])
def save_path():
    data = request.json
    all_paths = load_saved_paths()

    record = {
        "name": data.get("name", "Unnamed"),
        "points": data.get("points", []),
        "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    all_paths.append(record)
    save_saved_paths(all_paths)

    return jsonify({"status": "ok", "saved": record})

@app.route("/delete_path", methods=["POST"])
def delete_path():
    data = request.json
    name = data.get("name")

    all_paths = load_saved_paths()
    all_paths = [p for p in all_paths if p["name"] != name]

    save_saved_paths(all_paths)
    return jsonify({"status": "deleted", "name": name})

@app.route("/clear_saved_paths", methods=["POST"])
def clear_saved_paths():
    save_saved_paths([])
    return jsonify({"status": "cleared"})

@app.route("/clear_points", methods=["POST"])
def clear_points():
    with open(POINTS_FILE, "w") as f:
        json.dump([], f)
    return jsonify({"status": "points cleared"})

@app.route("/download/<name>")
def download(name):
    all_paths = load_saved_paths()
    for p in all_paths:
        if p["name"] == name:
            filename = f"{name}.json"
            with open(filename, "w") as f:
                json.dump(p, f, indent=4)
            return send_from_directory(".", filename, as_attachment=True)
    return "Not Found", 404

@app.route("/<path:path>")
def serve_static(path):
    return send_from_directory(".", path)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)