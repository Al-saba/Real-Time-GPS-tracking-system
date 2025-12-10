# Live GPS Map — README

## System Architecture Diagram

```
CLIENT SIDE
  ├─ Web Browser (index.html)
  │    ├─ Leaflet Map (OpenStreetMap)
  │    ├─ Sidebar (saved paths list)
  │    └─ Toolbar (action buttons)
  │
  ▼ HTTP (fetch API)

SERVER SIDE (Flask)
  ├─ server.py (Python Flask)
  │    ├─ /upload (POST) – receive GPS
  │    ├─ /saved_paths (GET) – list paths
  │    ├─ /save_path (POST) – save new path
  │    ├─ /delete_path (POST) – delete path
  │    └─ /clear_points (POST) – clear live
  │
  ▼ File I/O

DATA STORAGE (JSON files)
  ├─ points.json (live GPS data)
  └─ saved_paths.json (archived paths)

▼ POST Requests

GPS DATA GENERATORS
  ├─ fake_generator.sh – generates fake GPS
  └─ gps_to_web.sh – sends real GPS data
```

> **Bilingual:** English + বাংলা

---

## Project overview / প্রজেক্ট সারসংক্ষেপ

A minimal client-server setup for receiving, storing and visualizing GPS points in real-time. The client is a static web page (Leaflet map + sidebar). The server is a small Flask app that exposes simple HTTP endpoints to receive live GPS, list/save/delete archived paths, and clear live points. A fake GPS generator script simulates devices by POSTing JSON to the server.

রিয়েল-টাইম GPS পয়েন্ট রিসিভ করে তা সংরক্ষণ ও মানচিত্রে দেখানোর জন্য একটি লাইটওয়েট ক্লায়েন্ট-সার্ভার প্রজেক্ট। ক্লায়েন্ট হচ্ছে স্ট্যাটিক ওয়েব (Leaflet) এবং সার্ভার হচ্ছে Flask API। একটি fake_generator.sh স্ক্রিপ্ট সার্ভারে GPS ডেটা পাঠাতে পারে টেস্ট করার জন্য।

---

## Repository structure / ফাইল স্ট্রাকচার (উদাহরণ)

```
project-root/
├─ server.py            # Flask server
├─ requirements.txt     # pip dependencies
├─ points.json          # live GPS (overwritten)
├─ saved_paths.json     # archived/saved paths
├─ static/
│  ├─ index.html        # client page (Leaflet map + UI)
│  ├─ style.css
│  └─ script.js
├─ fake_generator.sh    # generates fake GPS and POSTs to server
└─ gps_to_web.sh        # optional: read real GPS serial and POST
```

---

## Prerequisites / প্রয়োজনীয়তা

* Python 3.8+ (recommend 3.10+)
* pip
* (Optional) git, curl
* On the client side: a modern browser (Chrome/Firefox)

---

## Setup & install / সেটআপ ও ইনস্টল

1. Create a virtual environment and install dependencies:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

`requirements.txt` should include at least:

```
Flask
Flask-Cors
```

2. Ensure `static/` files are present (`index.html`, `script.js`, `style.css`) and `points.json` / `saved_paths.json` exist (can start as empty arrays):

```json
# points.json
[]

# saved_paths.json
[]
```

---

## Running the server / সার্ভার চালানো

To run the Flask server (development mode):

```bash
export FLASK_APP=server.py
export FLASK_ENV=development  # optional
flask run --host=0.0.0.0 --port=5000
```

Or run directly with Python:

```bash
python server.py
```

Server will by default listen on port `5000`. Adjust host/port in `server.py` if needed.

---

## API endpoints (examples) / এন্ডপয়েন্টসমূহ (উদাহরণ)

> Base URL: `http://<server-host>:5000`

* `POST /upload` — receive a GPS point (live)

  **Expected JSON payload**:

  ```json
  {
    "device_id": "device123",
    "lat": 23.7775,
    "lon": 90.3995,
    "timestamp": "2025-12-08T12:34:56Z"
  }
  ```

  **curl example**:

  ```bash
  curl -X POST -H "Content-Type: application/json" \
    -d '{"device_id":"d1","lat":23.7775,"lon":90.3995}' \
    http://localhost:5000/upload
  ```

* `GET /saved_paths` — list archived paths (returns JSON array)

  ```bash
  curl http://localhost:5000/saved_paths
  ```

* `POST /save_path` — save current live points as a named path

  **Payload**:

  ```json
  {"name": "morning-run", "device_id": "d1"}
  ```

* `POST /delete_path` — delete an archived path (by id/name)

* `POST /clear_points` — clear live points (empty `points.json`)

(Adjust keys according to the `server.py` implementation.)

---

## Client (Leaflet) / ক্লায়েন্ট (Leaflet)

* `index.html` should load Leaflet CSS/JS and `script.js`.
* `script.js` periodically polls the server for live points (`/points` or `/upload` GET route) and renders them as a polyline or markers.
* Sidebar allows listing `/saved_paths` and actions (load path, delete, save current)

Tip: Use `fetch()` to call the API and update the map with new points.

---

## Fake GPS generator / ফেইক জিপিএস জেনারেটর

`fake_generator.sh` is a small bash script that posts fake GPS points to the server every N seconds. Example usage:

```bash
./fake_generator.sh --device-id device1 --interval 10 --url http://localhost:5000/upload
```

It typically:

* starts from a base lat/lon (e.g., Dhaka center)
* applies small random deltas to lat/lon to simulate movement
* sends JSON via `curl` to `/upload`

---

## Real GPS uploader (optional) / রিয়েল GPS আপলোডার

`gps_to_web.sh` can be used to read from a serial device (e.g., `/dev/ttyUSB0`) or a file with NMEA lines and POST parsed lat/lon to the server. Make sure you have `gpspipe`/`gpsd` or a parsing routine for NMEA if using a real GPS.

---

## Testing & troubleshooting / টেস্টিং ও সমস্যা সমাধান

* If the map shows but no points appear:

  * Verify the server logs that `/upload` requests are received.
  * Check browser console (CORS errors, fetch failures).
  * Make sure `points.json` is being updated by the server.

* If `curl` examples return errors, inspect `server.py` for required fields and JSON validation.

* Common issues: file permissions when server writes JSON files. Ensure the Flask process has write permissions to `points.json` and `saved_paths.json`.

---

## Security & production notes / নিরাপত্তা ও প্রোডাকশন নোট

This setup is meant for local testing and demos. For production:

* Add authentication to write endpoints (API keys / tokens).
* Serve static client files from a production-ready web server or CDN.
* Use a proper database if you need concurrency and durability instead of flat JSON files.
* Sanitize and validate all inputs before writing to disk.

---

## Example `server.py` skeleton / `server.py` খসড়া

> (Include in repo or adapt as you like)

```python
from flask import Flask, request, jsonify
from flask_cors import CORS
import json

app = Flask(__name__)
CORS(app)

POINTS_FILE = 'points.json'
SAVED_FILE = 'saved_paths.json'

@app.route('/upload', methods=['POST'])
def upload():
    data = request.get_json()
    # validate and append or replace live points
    # write to POINTS_FILE
    return jsonify({'status':'ok'})

@app.route('/saved_paths', methods=['GET'])
def saved_paths():
    with open(SAVED_FILE) as f:
        return jsonify(json.load(f))

# ... implement save_path, delete_path, clear_points

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

---

## License / লাইসেন্স

Use as you wish. Add a LICENSE file (MIT/Apache) if you plan to publish.

---

If you want, I can:

* create a ready-to-run `server.py` with full endpoint implementations,
* write `fake_generator.sh` example,
* produce a complete `index.html` + `script.js` client that works with this API.

চাইলে আমি `server.py`, `fake_generator.sh`, এবং কাজ করা `index.html` + `script.js` দেব।
