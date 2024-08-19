import React, { useState, useEffect } from 'react';
import ApexCharts from 'react-apexcharts';

const Dashboard = () => {
    const [chartData, setChartData] = useState({
        series: [{
            name: 'candlestick',
            type: 'candlestick',
            data: []
        }, 
        {
            name: 'SMA 20',
            type: 'line',
            data: []
        }],
        chart: {
            height: 350,
            type: 'candlestick'
        },
        title: {
            text: 'CandleStick Chart with SMA 20',
            align: 'left'
        },
        xaxis: {
            type: 'datetime'
        }
    });

    useEffect(() => {
        const ws = new WebSocket('ws://localhost:5000');

        ws.onopen = () => {
            console.log('Connected to WebSocket server');
        };

        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            console.log('Received data from server:', data);

            const timestamp = new Date(data.timestamp);

            if (isNaN(timestamp.getTime())) {
                console.error('Invalid timestamp:', data.timestamp);
                return;
            }

            const newCandle = {
                x: timestamp,
                y: [data.open_price, data.high_price, data.low_price, data.close_price]
            };

            const newSMA = {
                x: timestamp,
                y: data.sma_20
            };

            setChartData((prevData) => ({
                ...prevData,
                series: [{
                    ...prevData.series[0],
                    data: [...prevData.series[0].data, newCandle]
                },
                {
                    ...prevData.series[1],
                    data: [...prevData.series[1].data, newSMA]
                }]
            }));
        };

        ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };

        ws.onclose = () => {
            console.log('WebSocket connection closed');
        };

        return () => {
            ws.close();
        };
    }, []);

    return (
        <div id="chart">
            <ApexCharts
                options={chartData}
                series={chartData.series}
                type="candlestick"
                height={350}
            />
        </div>
    );
};

export default Dashboard;