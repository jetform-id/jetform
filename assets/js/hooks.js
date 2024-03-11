import ApexCharts from 'apexcharts'

let Hooks = {}

// Hooks.TrixEditor = {
//     updated() {
//         var trixEditor = document.querySelector("trix-editor")
//         if (null != trixEditor) {
//             trixEditor.editor.loadHTML(this.el.value);
//         }
//     }
// }


Hooks.RenderCaptcha = {
    mounted() {
        turnstile.render('#cf-turnstile', {
            sitekey: document.querySelector("meta[name='captcha-sitekey']").getAttribute("content")
        });
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
                categories: x
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
                }
            },
            legend: {
                position: 'top',
                horizontalAlign: 'right'
            }
        };

        var chart = new ApexCharts(document.querySelector("#SalesChart"), options);
        chart.render();
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
                }
            },
            legend: {
                position: 'top',
                horizontalAlign: 'right'
            }
        };

        var chart = new ApexCharts(document.querySelector("#VisitorsSalesChart"), options);
        chart.render();
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

        var chart = new ApexCharts(document.querySelector("#DownloadsChart"), options);
        chart.render();
    },
    mounted() {
        this.render()
    },
    updated() {
        this.render()
    }
}

export default Hooks