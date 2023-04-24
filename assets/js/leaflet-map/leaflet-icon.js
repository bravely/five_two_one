// Icons from https://github.com/pointhi/leaflet-color-markers

export const validColors = ['blue', 'gold', 'red', 'green', 'orange', 'yellow', 'violet', 'grey', 'black']

export const markerIcons = Object.fromEntries(
	validColors.map(color => [color, new L.Icon({
		iconUrl: `/images/marker-icon-2x-${color}.png`,
		shadowUrl: '/images/marker-shadow.png',
		iconSize: [25, 41],
		iconAnchor: [12, 41],
		popupAnchor: [1, -34],
		shadowSize: [41, 41]
	})])
)
