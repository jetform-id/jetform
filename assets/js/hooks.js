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
                type: 'bar',
                height: 250,
                fontFamily: 'Inter, sans-serif',
                foreColor: '#4B5563',
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
                show: true,
                width: 1,
                colors: ['transparent']
            },
            xaxis: {
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

        var chart = new ApexCharts(document.querySelector(".visitors-sales-chart"), options);
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