import { markerIcons } from "./leaflet-icon"

const getIcon = (color = 'blue') => markerIcons[color] ?? markerIcons['blue']

class LeafletMarker extends HTMLElement {
	static get observedAttributes() {
		return ['latitude', 'longitude', 'color']
	}

  constructor() {
    super()

    this.attachShadow({ mode: 'open' })
    this.parentMap = this.closest('leaflet-map')
    this.marker = L.marker(
      [
      this.getAttribute('latitude'),
      this.getAttribute('longitude')
      ], {
        icon: getIcon(this.getAttribute('color'))
      }).addTo(this.parentMap.map)
      this.parentMap.markerFeatureGroup.addLayer(this.marker)

      // So the click event makes it to Phoenix
      this.marker.on('click', this.click.bind(this)
    )

    if (this.hasChildNodes()) {
      this.marker.bindPopup(this.innerHTML)
    }
  }

  attributeChangedCallback(name, _oldValue, _newValue) {
    switch (name) {
      case 'color': {
        this.updateColor()
        break
      }
      case 'latitude':
      case 'longitude': {
        this.updatePosition()
        break
      }
    }
  }

  updateColor() {
    this.marker.setIcon(getIcon( this.getAttribute('color') ))
  }

  updatePosition() {
    this.marker.setLatLng([this.getAttribute('latitude'), this.getAttribute('longitude')])
  }
}

window.customElements.define('leaflet-marker', LeafletMarker)
