const map = L.map("map").setView([23.7775, 90.3995], 15);
L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png").addTo(map);

let currentPolyline = null;
let roadPoints = [];

// Load points.json and draw polyline
async function loadPoints() {
    const res = await fetch("points.json?time=" + Date.now());
    const data = await res.json();

    roadPoints = data.map(p => [p.lat, p.lon]);

    if (currentPolyline) map.removeLayer(currentPolyline);
    currentPolyline = L.polyline(roadPoints, { weight: 5 }).addTo(map);
}

// update every 2 sec
setInterval(loadPoints, 2000);

// Save Button
async function savePath() {
    const name = prompt("Enter path name:");
    if (!name) return;

    await fetch("/save_path", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, points: roadPoints })
    });

    loadSavedPaths();
}

// Load saved paths list
async function loadSavedPaths() {
    const res = await fetch("/saved_paths");
    const data = await res.json();

    const div = document.getElementById("savedPaths");
    div.innerHTML = "";

    data.forEach(p => {
        let row = document.createElement("div");
        row.className = "path-item";

        row.innerHTML = `
            <b>${p.name}</b> — ${p.points.length} points  
            <button onclick="showPath('${p.name}')">Show</button>
            <button onclick="deletePath('${p.name}')">Delete</button>
            <a href="/download/${p.name}"><button>Download</button></a>
        `;
        div.appendChild(row);
    });
}

// Show saved path
async function showPath(name) {
    const res = await fetch("/saved_paths");
    const paths = await res.json();
    const found = paths.find(p => p.name === name);

    if (!found) return;

    if (currentPolyline) map.removeLayer(currentPolyline);

    currentPolyline = L.polyline(found.points, { color: "red", weight: 5 }).addTo(map);
    map.fitBounds(currentPolyline.getBounds());
}

// Delete single path
async function deletePath(name) {
    await fetch("/delete_path", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name })
    });
    loadSavedPaths();
}

// Clear ALL saved paths
async function clearAllPaths() {
    await fetch("/clear_saved_paths", { method: "POST" });
    loadSavedPaths();

    // reload current points.json polyline after clearing
    loadPoints();
}

// Clear points.json
async function clearPoints() {
    await fetch("/clear_points", { method: "POST" });
}

loadSavedPaths();
