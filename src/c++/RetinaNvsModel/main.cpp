#include <stdio.h>
#include <vector>
#include "iostream"
#include "opencv2/opencv.hpp"

using namespace std;
using namespace cv;

int numFrames = 300;

struct Parameter {
    double percent_threshold_variance = 2.5;
    int enable_diffusive_net = 1;
    int enable_temporal_low_pass = 1;
    int enable_threshold_variance = 1;
    int frames_per_second = 60;
    double threshold = 20.0;
    Mat on_threshold, off_threshold;
};

struct Event {
    int x;
    int y;
    int pol;
    double ts;
};

double Normrnd(double mean, double stdDev) {
    double u, v, s;
    do {
        u = ((double)rand() / (double)RAND_MAX) * 2.0 - 1.0;
        v = ((double)rand() / (double)RAND_MAX) * 2.0 - 1.0;
        s = u * u + v * v;
    } while (s >= 1 || s == 0);
    double mul = sqrt(-2.0 * log(s) / s);
    return mean + stdDev * u * mul;
}

Mat AddNormrnd(Mat frame, int rows, int cols, double mean, double sigma) {
    Mat result = frame;
    for (int k = 0; k < rows; k++) {
        for (int i = 0; i < cols; i++)
            result.at<double>(k, i) =
                frame.at<double>(k, i) + Normrnd(mean, sigma);
    }
    return result;
}

void NormalizeContrast(Mat &frame) {
    double alpha = 5.0;
    int ksize = 9;
    int row = frame.rows;
    int col = frame.cols;
    Mat horiz(row, col, CV_8UC1);
    Mat pr(row, col, CV_8UC1);
    GaussianBlur(frame, horiz, Size(ksize, ksize), 2.5, 2.5, BORDER_REPLICATE);
    GaussianBlur(frame, pr, Size(ksize, ksize), 2, 2, BORDER_REPLICATE);
    Mat img_c(row, col, CV_16F);
    img_c = alpha * pr - horiz;
    horiz.convertTo(horiz, CV_64F);
    img_c.convertTo(img_c, CV_64F);
    divide(img_c, horiz, img_c, 1, CV_64F);
    img_c -= (alpha - 1);  // bring to 0
    double min, max;
    minMaxLoc(img_c, &min, &max);
    img_c = img_c - min;  // bring to positive
    minMaxLoc(img_c, &min, &max);
    img_c = img_c / max * 255;  // normalize and scale
    frame.convertTo(img_c, CV_8U);
}

void processFrames(Parameter params, VideoCapture camera) {
    Mat frames[numFrames];  // array of frames
    double tframe = (double)1 / params.frames_per_second;
    for (int k = 0; k < numFrames; k++) {
        camera >> frames[k];  // capture the next frames[k] from the webcam
        cvtColor(frames[k], frames[k], COLOR_BGR2GRAY);
    }
    int rows = frames[0].rows;
    int cols = frames[0].cols;
    double threshold_variance =
        params.percent_threshold_variance / 100 * params.threshold;
    // Mat threshold_variance_on(rows, cols, CV_64F, threshold_variance);
    // Mat threshold_variance_off(rows, cols, CV_64F, threshold_variance);
    params.on_threshold = Mat(rows, cols, CV_64F, params.threshold);
    params.off_threshold = Mat(rows, cols, CV_64F, params.threshold);
    Mat on_threshold =
        AddNormrnd(params.on_threshold, rows, cols, 0, threshold_variance);
    Mat off_threshold =
        AddNormrnd(params.off_threshold, rows, cols, 0, threshold_variance);

    int ksize = 9;
    Mat I_mem, I_mem_p;
    I_mem = 0;
    double T = 0; //cur.T
    int evtCount = 0;

    for (int k = 1; k < numFrames; k++)  // starting from the second frame
    {
        // horizontal cells
        if (params.enable_diffusive_net) NormalizeContrast(frames[k]);

        I_mem_p = I_mem;

        if (params.enable_temporal_low_pass) {
            Mat temp = frames[k];
            frames[k].setTo(0.05, frames[k] < 0.05);  // low-pass filter
            Mat temporal_lp_response = frames[k];
            frames[k] = temp;
            frames[k] = frames[k] * temporal_lp_response +
                        (1 - temporal_lp_response) * frames[k - 1];
            if (numFrames == 1) continue;
        }

        // bipolar cells
        Mat dI = frames[k] - frames[k - 1];
        I_mem += dI;
        T += tframe;

        // ganglion cells
        for (int k = 0; k < rows; k++) {
            for (int i = 0; i < cols; i++) {
                double theta_on, theta_off;
                int p, nevents;
                if (params.enable_threshold_variance) {
                    theta_on = on_threshold.at<double>(k, i);
                    theta_off = off_threshold.at<double>(k, i);
                } else {
                    theta_on = params.on_threshold.at<double>(k, i);
                    theta_off = params.off_threshold.at<double>(k, i);
                }
                if (I_mem.at<double>(k, i) > I_mem_p.at<double>(k, i)) {
                    p = 1;
                    nevents = floor(
                        abs(I_mem.at<double>(k, i) - I_mem_p.at<double>(k, i)) /
                        theta_on);
                } else {
                    p = -1;
                    nevents = floor(
                        abs(I_mem.at<double>(k, i) - I_mem_p.at<double>(k, i)) /
                        theta_off);
                }
                double ts;
                if (nevents > 1) {
                    I_mem.at<double>(k,i) = 128;
                }
                if (nevents > 0) {
                    for (int ee = 0, ts = T; ee < nevents; ee++, ts += tframe/nevents) {
                        
                    } 
                }

            
            }
        }
    }

    for (Mat frame : frames) {
        imshow("Webcam", frame);  // show the image on the window
        // wait (10ms) for a key to be pressed
        // if (waitKey(10) >= 0)
        //     break;
    }
    return;
}

int main(int, char **) {
    // open the first webcam plugged in the computer

    VideoCapture camera(0);
    if (!camera.isOpened()) {
        cerr << "ERROR: Could not open camera" << endl;
        return 1;
    }

    // create a window to display the images from the webcam
    namedWindow("Webcam", WINDOW_AUTOSIZE);
    Parameter params;
    processFrames(params, camera);
    return 0;
}
