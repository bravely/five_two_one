export const setupMap = (map) => {
	L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
			maxZoom: 19,
			attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
	}).addTo(map);
}

export const createPopup = (attrs) => {
	return L.popup()
    .setLatLng([attrs.lat, attrs.lng])
		.setContent(attrs.name)
}
