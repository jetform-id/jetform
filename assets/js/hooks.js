import ClipboardJS from "clipboard/dist/clipboard"
import Glide from '@glidejs/glide'
import ApexCharts from 'apexcharts'
import Prism from 'prismjs'
import Trix from "trix"

let Hooks = {}

Hooks.InitTrix = {
    mounted() {
        const target = this.el
        document.addEventListener("trix-change", () => {
            target.dispatchEvent(new Event("input", { bubbles: true }))
        })
    }
}

Hooks.InitJetformWidget = {
    updated() {
        Prism.highlightAll();
        window.JetformWidget.init();
    }
}

Hooks.Embed = {
    mounted() {
        // send message to parent window to close the embed
        let closeBtn = document.getElementById("close-embed")
        if(closeBtn !== null) {
            closeBtn.addEventListener("click", () => {
                window.parent.postMessage({action: "jf:closepopup"}, "*");
            })
        }
        window.addEventListener("phx:openurl", (e) => {
            window.parent.postMessage({action: "jf:openurl", url: e.detail.url}, "*");
        })

        // open all external links in new tab
        document.querySelectorAll('.trix-content a').forEach((el) => {
            el.onclick = (e) => {
                e.preventDefault()
                window.open(el.getAttribute("href"), "_blank")
            }
        })
    }
}

function getUrlAndReferrer(trackingUrl) {
    windowUrl = new URL(window.location.href)
    var referrer = document.referrer
    if (windowUrl.searchParams.has("referrer")) {
        referrer = decodeURIComponent(windowUrl.searchParams.get("referrer"))
        windowUrl.searchParams.delete("referrer")
    }
    if (windowUrl.searchParams.has("mode")) {
        windowUrl.searchParams.delete("mode")
    }
    let searchParamsStr = windowUrl.searchParams.toString()
    return {
        url: trackingUrl + (searchParamsStr !== "" ? "?" + searchParamsStr : ""),
        referrer: referrer
    }
}

Hooks.UmamiView = {
    mounted() {
        let send = this.el.dataset.if === undefined || this.el.dataset.if === "true"
        if(!send) return
        
        let urlAndReferrer = getUrlAndReferrer(this.el.dataset.url)
        umami.track(props => ({
            ...props,
            ...urlAndReferrer,
            data: {href: window.location.href}
        }))
    }
}

Hooks.UmamiClick = {
    mounted() {
        let send = this.el.dataset.if === undefined || this.el.dataset.if === "true"
        if(!send) return

        let urlAndReferrer = getUrlAndReferrer(this.el.dataset.url)
        let eventName = this.el.dataset.event
        
        this.el.addEventListener("click", () => {
            umami.track(props => ({
                ...props, 
                ...urlAndReferrer,
                name: eventName, 
                data: {...this.el.dataset, href: window.location.href}
            }))
        })
    }
}

Hooks.InitClipboard = {
    init() {
        const clipboard = new ClipboardJS('.clipboard')
        clipboard.on('success', function(e) {
            alert("Data disalin ke clipboard")
        })
    },
    mounted() {
        this.init()
    },
    updated() {
        this.init()
    }
}

Hooks.InitGlide = {
    init() {
        const config = {
            gap: 0,
            hoverpause: true
        }
        if (this.el.dataset.autostart == "true") {
            config.autoplay = 5000
        }
        new Glide('.glide', config).mount()
    },
    mounted() {
        this.init()
    },
    updated() {
        this.init()
    }
}

Hooks.RenderCaptcha = {
    render() {
        turnstile.render('#cf-turnstile', {
            sitekey: document.querySelector("meta[name='captcha-sitekey']").getAttribute("content")
        })
    },
    mounted() {
        this.render()
    },
    updated() {
        this.render()
    }
}

Hooks.SalesChart = {
    render() {
        const x = []
        const y1 = []
        const y2 = []
        JSON.parse(this.el.dataset.buckets).forEach((item) => {
            x.push(item.x)
            y1.push(item.y1)
            y2.push(item.y2)
        })
        var options = {
            series: [
                {
                    name: 'Download gratis',
                    data: y1
                },
                {
                    name: 'Penjualan',
                    data: y2
                }
            ],
            chart: {
                type: 'area',
                height: parseInt(this.el.dataset.height) || 250,
                fontFamily: 'Inter, sans-serif',
                toolbar: {
                    show: false
                }
            },
            grid: {
                show: true
            },
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth',
                show: true,
                width: 1
            },
            xaxis: {
                type: 'datetime',
                categories: x,
            },
            yaxis: {
                min: 0,
                decimalsInFloat: 0,
                forceNiceScale: true
            },
            fill: {
                opacity: 1
            },
            tooltip: {
                y: {
                    formatter: function (val) {
                        return Math.round(val)
                    }
                },
                x: {
                    formatter: function (value, { series, seriesIndex, dataPointIndex, w }) {
                        return new Date(value).toLocaleDateString()
                    }
                }
            },
            legend: {
                position: 'top',
                horizontalAlign: 'right'
            }
        }

        var chart = new ApexCharts(document.querySelector("#SalesChart"), options)
        chart.render()
    },
    mounted() {
        this.render()
    }
}

Hooks.VisitorsSalesChart = {
    render() {
        const x = []
        const y1 = []
        const y2 = []
        JSON.parse(this.el.dataset.buckets).forEach((item) => {
            x.push(item.x)
            y1.push(item.y1)
            y2.push(item.y2)
        })
        var options = {
            series: [
                {
                    name: 'Pageviews',
                    data: y1
                },
                {
                    name: 'Penjualan',
                    data: y2
                }
            ],
            chart: {
                type: 'area',
                height: parseInt(this.el.dataset.height) || 250,
                fontFamily: 'Inter, sans-serif',
                toolbar: {
                    show: false
                }
            },
            plotOptions: {
                bar: {
                    horizontal: false,
                    columnWidth: '55%',
                    endingShape: 'rounded',
                    borderRadius: 2
                },
            },
            grid: {
                show: true
            },
            dataLabels: {
                enabled: false
            },
            stroke: {
                curve: 'smooth',
                show: true,
                width: 1
            },
            xaxis: {
                type: 'datetime',
                categories: x
            },
            yaxis: {
                decimalsInFloat: 0,
                forceNiceScale: true
            },
            fill: {
                opacity: 1
            },
            tooltip: {
                y: {
                    formatter: function (val) {
                        return Math.round(val)
                    }
                },
                x: {
                    formatter: function (value, { series, seriesIndex, dataPointIndex, w }) {
                        return new Date(value).toLocaleDateString()
                    }
                }
            },
            legend: {
                position: 'top',
                horizontalAlign: 'right'
            }
        }

        var chart = new ApexCharts(document.querySelector("#VisitorsSalesChart"), options)
        chart.render()
    },
    mounted() {
        this.render()
    },
    updated() {
        this.render()
    }
}

Hooks.DownloadsChart = {
    render() {
        var options = {
            chart: {
                type: 'area',
                height: parseInt(this.el.dataset.height) || 80,
                sparkline: {
                    enabled: true
                },
            },
            stroke: {
                curve: 'smooth',
                width: 1,
            },
            fill: {
                opacity: 1,
            },
            series: [{
                name: 'Downloads',
                data: JSON.parse(this.el.dataset.buckets)
            }],
            xaxis: {
                type: 'datetime'
            },
            yaxis: {
                min: 0
            }
        }

        var chart = new ApexCharts(document.querySelector("#DownloadsChart"), options)
        chart.render()
    },
    mounted() {
        this.render()
    },
    updated() {
        this.render()
    }
}

export default Hooks