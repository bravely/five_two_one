import L from 'leaflet'

const template = document.createElement('template')
template.innerHTML = `
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.3/dist/leaflet.css"
     integrity="sha256-kLaT2GOSpHechhsozzB+flnD+zUyjE2LlfWPgU04xyI="
     crossorigin=""/>
	<div style="height: 500px;">
			<slot />
	</div>
`

class LeafletMap extends HTMLElement {
	static get observedAttributes() {
		return ['latitude', 'longitude', 'zoom']
	}

	constructor() {
			super()

			this.attachShadow({ mode: 'open' })
			this.shadowRoot.appendChild(template.content.cloneNode(true))

			this.mapElement = this.shadowRoot.querySelector('div')
			this.map = L.map(this.mapElement)
			this.updateMap()
			L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png?{retina}', {
					retina: '',  // to be extended for detected Retina displays with value '@2x'
					attribution: '&copy <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'}
			).addTo(this.map)

			// This is for auto-zooming the map to fit all markers whenever one is added or removed
			this.markerFeatureGroup = L.layerGroup()
	}

	attributeChangedCallback(_name, _oldValue, _newValue) {
		this.updateMap()
	}

	updateMap() {
		this.map.setView([this.getAttribute('latitude'), this.getAttribute('longitude')], this.getAttribute('zoom') ?? 13)
	}

	fitToMarkers() {
		this.map.fitBounds(this.markerFeatureGroup.getBounds().pad(0.5))
	}

	connectedCallback() {
		this.markerFeatureGroup.addEventListener('layeradd', this.fitToMarkers.bind(this))
	}

	disconnectedCallback() {
		this.markerFeatureGroup.removeEventListener('layeradd', this.fitToMarkers.bind(this))
	}
}

window.customElements.define('leaflet-map', LeafletMap)
