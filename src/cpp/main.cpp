#include <stdio.h>

#include <chrono>
#include <random>
#include <vector>

#include "iostream"
#include "opencv2/opencv.hpp"

using namespace std;
using namespace cv;

// global variables
double timescale = 10e-6;       // S
double q = 1.62e-19;            // C
double average_current = 1e-9;  // A
int num_devices = 10;
int ksize = 15;
int rows = 512;
int cols = 512;
int numFrames = 200;

struct Parameter {
    double percent_threshold_variance = 2.5;
    int frame_show = 1;
    int enable_threshold_variance = 1;
    int enable_pixel_variance = 0;
    int enable_diffusive_net = 1;
    int enable_temporal_low_pass = 1;

    int enable_leak_ba = 1;
    int leak_ba_rate = 40;
    int frames_per_second = 30;
    int enable_refractory_period = 1;
    double refractory_period = 1.0 / frames_per_second;

    int inject_spike_jitter = 1;
    double threshold = 20.0;
    Mat on_threshold, off_threshold;
};

struct Event {
    int x;
    int y;
    int pol;
    double ts;
};

int ReadVideo(vector<Mat> &frames) {
    VideoCapture video(
        "/Users/susanliu/Documents/AndreouResearch/videos/livingroom_walk.mp4");
    if (!video.isOpened()) {
        cerr << "ERROR: Could not load videos" << endl;
        return 0;
    }
    Mat frame;
    int count = 0;
    while (1) {
        video >> frame;
        if (frame.empty()) break;
        cvtColor(frame, frame, COLOR_BGR2GRAY);
        resize(frame, frame, Size(cols, rows), 0, 0, INTER_CUBIC);
        frames.push_back(frame);
        if (count >= numFrames) break;
        count++;
    }
    video.release();
    return count;
}

double Normrnd(float mean, float stdDev) {
    // double u, v, s;
    // do {
    //     u = ((double)rand() / (double)RAND_MAX) * 2.0 - 1.0;
    //     v = ((double)rand() / (double)RAND_MAX) * 2.0 - 1.0;
    //     s = u * u + v * v;
    // } while (s >= 1 || s == 0);
    // double mul = sqrt(-2.0 * log(s) / s);
    // return mean + stdDev * u * mul;
    normal_distribution<float> dist(mean, stdDev);
    default_random_engine generator;
    return dist(generator);
}

double Normrnd_(double mean, double stdDev) {
    double u, v, s;
    do {
        u = ((double)rand() / (double)RAND_MAX) * 2.0 - 1.0;
        v = ((double)rand() / (double)RAND_MAX) * 2.0 - 1.0;
        s = u * u + v * v;
    } while (s >= 1 || s == 0);
    double mul = sqrt(-2.0 * log(s) / s);
    return mean + stdDev * u * mul;
}

Mat AddNormrnd(Mat frame, double mean, double sigma) {
    Mat result = frame.clone();
    for (int k = 0; k < rows; k++) {
        for (int i = 0; i < cols; i++)
            result.at<float>(k, i) =
                frame.at<float>(k, i) + Normrnd(mean, sigma);
    }
    return result;
}

void Normrnd(Mat &frame, float mean, Mat sigma) {
    sigma.convertTo(sigma, CV_32F);
    for (int k = 0; k < rows; k++) {
        for (int i = 0; i < cols; i++) {
            float sig = sigma.at<float>(k, i);
            frame.at<float>(k, i) = Normrnd(mean, sig);
        }
    }
}

void NormalizeContrast(Mat &frame) {
    double alpha = 1;
    int ksize = 15;
    Mat horiz(rows, cols, CV_32F);
    Mat pr(rows, cols, CV_32F);
    GaussianBlur(frame, horiz, Size(ksize, ksize), 2.5, 2.5, BORDER_REPLICATE);
    GaussianBlur(frame, pr, Size(ksize, ksize), 2, 2, BORDER_REPLICATE);
    Mat img_c(rows, cols, CV_32F);
    img_c = alpha * pr - horiz;
    double min, max;
    minMaxLoc(img_c, &min, &max);
    img_c = img_c - min;  // bring to positive
    minMaxLoc(img_c, &min, &max);
    frame = img_c / max * 255;  // normalize and scale
    // cout << frame;
}

void UniformInit(double *arr, double start, double spacing, int num) {
    int idx = 0;
    for (double k = start; idx < num; k += spacing, idx++) arr[idx] = k;
}

void processFrames(Parameter params) {
    double tframe = (double)1 / params.frames_per_second;
    vector<Event> td;
    VideoCapture camera;
    if (!camera.open(0)) return;
    vector<Mat> frames;
    vector<Mat> curFrames;
    double threshold_variance =
        params.percent_threshold_variance / 100 * params.threshold;
    params.on_threshold = Mat(rows, cols, CV_32F, params.threshold);
    params.off_threshold = Mat(rows, cols, CV_32F, params.threshold);
    Mat on_threshold = AddNormrnd(params.on_threshold, 0, threshold_variance);
    Mat off_threshold = AddNormrnd(params.off_threshold, 0, threshold_variance);

    Mat I_mem(rows, cols, CV_32F, 128);
    Mat I_mem_p(rows, cols, CV_32F, 128);
    Mat pixel_fe_noise(rows, cols, CV_32F);
    Mat pixel_fe_noise_past(rows, cols, CV_32F);
    Mat lp_log_in(rows, cols, CV_32F);
    Mat sae(rows, cols, CV_32F, 0.0);
    double T = 0;  // cur.T
    int evtCount = 0;
    Mat curFrame, pastFrame;
    double min, max;
    double noise =
        sqrt(2 * num_devices * average_current * q * (1 / timescale)) /
        average_current;
    Mat pix_shot_rate;

    // vector<Mat> frames;
    // int numFrames = ReadVideo(frames);
    // cout << "-----Read " << numFrames << " frames-----" << endl;
    // if (numFrames == 0) return;
    // clock_t tic = clock();
    for (int fr = 0; ; fr++) {
        Mat frame;
        camera >> frame;  // capture the next frames[k] from the webcam
        cvtColor(frame, frame, COLOR_BGR2GRAY);
        resize(frame, frame, Size(cols, rows), 0, 0, INTER_CUBIC);
        frames.push_back(frame);
        if (fr == 0) {
            curFrames.push_back(frames[0]);
            continue;
        }
        namedWindow("Webcam", WINDOW_AUTOSIZE);  // create a window to display
                                                 // the images from the webcam
        frames[fr].convertTo(curFrame, CV_32F);
        minMaxLoc(curFrame, &min, &max);

        if (params.enable_pixel_variance) {
            if (fr == 1) {  // needs to calculate past noise first
                Mat frame_32f;
                double pmin, pmax;
                frames[0].convertTo(frame_32f, CV_32F);
                minMaxLoc(frame_32f, &min, &max);
                pix_shot_rate = noise * (max - frame_32f);
                Normrnd(pixel_fe_noise_past, 0.0, pix_shot_rate);
            }

            pix_shot_rate = noise * (max - curFrame);
            Normrnd(pixel_fe_noise, 0.0, pix_shot_rate);
            add(frames[fr - 1], pixel_fe_noise_past, pastFrame, Mat(), CV_32F);
            add(frames[fr], pixel_fe_noise, curFrame, Mat(), CV_32F);
            pixel_fe_noise_past = pixel_fe_noise.clone();
        } else {
            pastFrame = frames[fr - 1].clone();
            pastFrame.convertTo(pastFrame, CV_32F);
        }
        // horizontal cells
        if (params.enable_diffusive_net) {
            NormalizeContrast(curFrame);
            NormalizeContrast(pastFrame);
        }
        curFrame.convertTo(frame, CV_8U);
        curFrames.push_back(frame);
        
        I_mem_p = I_mem.clone();

        if (params.enable_leak_ba) {
            I_mem -= tframe * params.leak_ba_rate;
        }
        if (params.enable_temporal_low_pass) {
            // minMaxLoc(curFrame, &min, &max);
            // Mat temporal_lp_response = curFrame / max;
            // temporal_lp_response.setTo(
            //     0.05, temporal_lp_response < 0.05);  // low-pass filter
            double temporal_lp_response = 0.9;
            curFrame = curFrame * temporal_lp_response +
                       pastFrame * (1 - temporal_lp_response);
            pastFrame = pastFrame * temporal_lp_response +
                        lp_log_in * (1 - temporal_lp_response);
            lp_log_in = pastFrame.clone();
        }
        // bipolar cells
        Mat dI = curFrame - pastFrame;
        I_mem += dI;

        T += tframe;
        // ganglion cells
        for (int ii = 0; ii < rows; ii++) {
            for (int jj = 0; jj < cols; jj++) {
                double theta_on, theta_off;
                int p, nevents;
                if (params.enable_threshold_variance) {
                    theta_on = on_threshold.at<float>(ii, jj);
                    theta_off = off_threshold.at<float>(ii, jj);
                } else {
                    theta_on = params.on_threshold.at<float>(ii, jj);
                    theta_off = params.off_threshold.at<float>(ii, jj);
                }

                double mem = I_mem.at<float>(ii, jj);
                double mem_p = I_mem_p.at<float>(ii, jj);
                if (mem > mem_p) {
                    p = 1;
                    nevents = floor((mem - mem_p) / theta_on);
                } else {
                    p = -1;
                    nevents = floor(abs(mem - mem_p) / theta_off);
                }
                double ts[nevents];
                if (nevents > 1) {
                    I_mem.at<float>(ii, jj) = 128;
                    UniformInit(ts, T, tframe / nevents, nevents);
                } else if (nevents == 1)
                    ts[0] = T + tframe / 2;
                for (int ee = 0; ee < nevents; ee++) {
                    if (params.inject_spike_jitter)
                        ts[ee] += Normrnd(0, tframe / 100);

                    Event e = {jj, ii, p, (double)ts[ee]};
                    if (params.enable_refractory_period) {
                        if (ts[ee] - sae.at<float>(ii, jj) >
                            params.refractory_period) {
                            td.push_back(e);
                            evtCount++;
                            sae.at<float>(ii, jj) = ts[ee];
                        }
                    } else {
                        td.push_back(e);
                        evtCount++;
                    }
                }
            }
        }

        // tic = clock() - tic;
        // cout << evtCount << " events generated" << endl;
        // cout << (float)tic / CLOCKS_PER_SEC << " seconds took with event
        // generation" << endl;
        if (params.frame_show) {
            imshow("Webcam", curFrames[fr]);
            // for (Mat frame : curFrames) {
            //     imshow("Webcam", frame);  // show the image on the window
            //     // wait (25ms) for a key to be pressed
            //     if (waitKey(25) >= 0) break;
            // }
        }
        if (waitKey(25) >= 0) break;
    }
    return;
}

int main(int, char **) {
    // open the first webcam plugged in the computer

    Parameter params;

    processFrames(params);
    destroyAllWindows();

    return 0;
}
