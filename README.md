# Overview
As part of an assignment for ECE 3040 : Numerical Methods, I developed a system to simulate & detect a heartbeat, applying predictive math & signal processing techniques to provide accurate, real-time information. The system was built using MATLAB, Arduino, ultrasonic sensors and servo motors. Signal-processing techniques such as digital filters, regression & polynomial curve fitting, were used to predict data with an error threshold of <0.05%. 

Next, the data was integrated with a MATLAB GUI that allowed the user to see visual plots of the raw data and filtered data, save the results and see the average heart rate of the signal. 
## Features
- Signal processing to provide real-time predictions for user's heart rate
- Hardware and Software Integration for collecting clean and usable data
- Ability to preload dataset to run through filtering process
- Servo motor that moves with heart-beat, providing visual information on the heart rate
- Interactive & visually-appealing GUI that integrates hardware & sensor data through different functions
- LED status light to indicate if corrupt data is being collected

![enter image description here](https://media-hosting.imagekit.io//a85c1736608a4e03/screenshot_1739053968333.png?Expires=1833661967&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=X00e6yZ9lVW8UgyMy08rXo2zo4sHzQFogGk2hMcOFBZUx2ccL8-1iw7FlnSIDx5MqxVyUqt0v1qizCPzKCnOA2YGOlnjo3dOaHSP6WkquamUWqsjS5SWhgt7qTUKKNPG9QTE7sRg0PZGJIEoF0iibLDjbH3T58YAker8J2fiUFr6ykn8uuCmSolOSbenIl4Pytky~kO~qohbILzRWa8MozCeEUStbvIuw337g7L9WL5jrgdHchLWkQtsEtyJqRvvz2PfItyoUrFD3dtB9mjMD8Q1Lb0E1~3rbeKUWjSjYi6g2Ql-ukb87VMqz92Tn02B~9zUfSztHzBH1EEruufwIw__)
[*GUI Interface]*

## Development Process

1. First, to integrate the required hardware with MATLAB, I had to use the Arduino package & set the pins for the connected ultrasonic sensor. Then, the data was plotted in real time as the sensor collected information (example below). 
![enter image description here](https://media-hosting.imagekit.io//f7cc8f03992643d8/screenshot_1739053928464.png?Expires=1833661927&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=IS0LxZrVUSRt1pxi7BFAhO6hNJvgoNdqaBKLTieXcfvro7ZIJ2U-piHpN0emhP8lplRqNcYcpI1PKI34Hnv67xUyNvPmvnlPSPGL2jnm3ebazHbDMHEUtxl-S9fbHgBeWNKkxD6jgdvlJP3pL2YUzvkvnLWteAGzG5t3wXZZCOml4HEgCjdSRBt2C8Kz19tzb56mu0Lv1QSFzHmJoAX3~-MiV3ITqm03LJeRO3hiNB8dlkKrB9m-cPCU25iD7QXGcekAnF3XZBJmePsDvCPKI5GP4XM0YNP1WvqovaQsVy9SgtbvWML0o4v4~o91ApICYfFo0VlCWDmJwe2FlyMKGw__)

2. However, the collected data was not useable to calculate the BPM (beats per minute) of the simulated heart. Excessive noise occurred every few seconds or so, causing random peaks & values of infinity to be collected. Various numerical & processing methods were used to turn the data into usable values. 
 
To determine the best approach, I experimented with various methods, such as using digital filters (low pass Butterworth) and manually filtering out values of null and inf. 

3. While the data was plotted in real-time, to improve accuracy and usability of the project, I implemented numerical solutions to predict data within a 0.1 second accuracy.  This included interpolation & polynomial curve fitting with different orders (2-7). A lower order polynomial was determined to be more feasible, and implemented through MATLAB's polyfit and polyval. 

## How to Run 
- Setup an Arduino and ultrasonic sensor & connect them to MATLAB using the Arduino package add-on. 
- Open the GUI, and initialize the setup. Then either load pre-saved files or allow the data to plot in real-time. 
