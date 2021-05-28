import cv2
import numpy as np
import math as mt
import glob 
import scipy.io as sio
import struct
import os
import dv
import time 
import functools
from operator import itemgetter 

from datetime import datetime

from aerpyproc import Events

"""
Class RetinaNvsModel 
models the NVS and incorporates biological influences as well

parameters:

    thr: on/off_threshold
    thr_var: percent_threshold_variance
    leakage_rate:
    enable_diffusive_net:
    show_frame:
    fps:
"""

"""
to - do 
spatial contrast hc response - represent illumination independent 
new bc reponses
"""
class RetinaNvsModel(object):
    name = 'RetinaNvsModel'
    def __init__(self, 
                thr = [0.25,0.25], 
                thr_var = 2.5,
                leakage_rate = 10,
                enable_diffusive_net = False, 
                show_frame = False, 
                fps = 100, 
                im_dim = (720,1280), 
                isprint = False):
        
        self.enable_diffusive_net = enable_diffusive_net
        self.t = 0
        self.dt = 1/fps
        self.el = leakage_rate*self.dt
        self.im_dim = im_dim
        self.isprint = isprint

        self.pframe = self.vmem = mt.log(128)*np.ones((im_dim[0:2]),dtype=np.uint8)
        self.ppframe = mt.log(128)*np.ones((im_dim[0:2]),dtype=np.uint8)

        print(self.pframe.shape)
        print(self.ppframe.shape)

        threshold_variance = [(thr_var/100 * thr_) for thr_ in thr]
        threshold_variance_matrices = [np.reshape(np.random.normal(0,threshold_variance_,im_dim[0]*im_dim[1]), (im_dim[0:2])) for threshold_variance_ in threshold_variance]

        self.ganglion_thresholds = [thr_ * np.ones(im_dim[0:2]) + threshold_variance_matrices[ct] for ct, thr_ in enumerate(thr)]

        self.td = Events(num_events=0, sensor_dims=im_dim)

        self.max_events = int(100e6)

        print("%s initialized!" % self.name)
        
        self.f_frame = True

    def __call__(self, frames):

        f = 0
        print("here")
        # Check if it is a stream of frames or a single frame
        try:
            assert(frames[0].shape[0] == self.im_dim[0])
        except: # Create list with single element
            frames = [frames]

        for frame in frames:

            if frame.shape[1] != self.im_dim[1]:
                frame = frames

            if self.isprint:
                print("Frame: %d" % (f))
                print("Time: %0.4f seconds" % (self.t))

            pframe = self.pframe # already spatially and temporally filtered from last iteration
            
            if len(frame.shape) == 3:
                yframe = 0.29 * frame[:,:,0] + 0.58 * frame[:,:,1] + 0.114 * frame[:,:,2]
            else:
                yframe = frame

            if not self.f_frame:
                t0 = time.time()
                # photoreceptor layer
                pr_past, pr_cur = self.photoreceptor(yframe)
                # bipolar layer
                bc = self.bipolar(pr_cur,pr_past)
                # ganglion layer
                eframe, events = self.ganglion(bc, self.vmem)
                # store update bipolar potential
                self.vmem = bc
                # add events to event class 
                [self.td.data.append(datum) for datum in events]

                t3 = time.time()

                if self.isprint:
                    print("Full Model took %s seconds" % ((t3-t0)))
                if len(self.td.data) >  self.max_events:
                    self.td.data = self.td.data[-self.max_events:]
                # sort event class based on timestamps
                self.td.sort_td()
            else:
                self.f_frame = False
                events = {}

            # shift values
            self.ppframe = self.pframe
            self.pframe = yframe
            # increment global time
            self.t += self.dt
            f += 1
            if self.isprint:
                print("Number of events: %d" %(len(self.td.data)))

        return events
            
    """
    Photoreceptor Cells

    Input:
    frame
    Outputs:
    current photoreceptor response
    past photoreceptor response 
    """
    # @timer
    def photoreceptor(self, frame):

        frame = np.log(frame)
        pframe = np.log(self.pframe)
        ppframe = np.log(self.ppframe)
        # spatial lowpass
        if self.enable_diffusive_net:
            frame = cv2.GaussianBlur(frame,(5,5),0)
            pframe = cv2.GaussianBlur(pframe,(5,5),0)
            ppframe = cv2.GaussianBlur(ppframe,(5,5),0)

        # temporal lowpass based on intensity
        tau_cur = self.get_tau(frame, 0.05)
        tau_past = self.get_tau(pframe, 0.05)

        pr_cur_response = np.multiply(tau_cur,frame) + np.multiply(1-tau_cur,pframe) 
        pr_past_response = np.multiply(tau_past,pframe) + np.multiply(1-tau_past,ppframe) 
    
        return pr_past_response, pr_cur_response

    """
    Bipolar Cells

    Input:
    current frame - 2D array of values from current frame
    past frame - "" prior frame
    Outputs:
    bipolar potential 
    """
    # @timer
    def bipolar(self, frame, pframe):

        #leak
        self.vmem = self.vmem - self.el
        #difference
        dI = frame - pframe 

        return self.vmem+dI

    """
    Ganglion Cells

    Input:
    bipolar potential - 2D array
    Outputs:
    eventframe
    events
    """
    # @timer
    def ganglion(self, gc_in, gc_in_p):

        eframe = 128*np.ones(self.im_dim)

        #create iterator with multivalue indexes available
        it = np.nditer(gc_in, flags=['multi_index'])

        #iterate through 2D array and generate events
        events = []
        for gc_in_ in it:
            x, y =  it.multi_index[1], it.multi_index[0]

            thresholds = [self.ganglion_thresholds[0][y,x], -1*self.ganglion_thresholds[1][y,x]]
            
            #generate events                
            nevents, pol = self.gen_events(thresholds, gc_in_ - gc_in_p[y,x])

            # if events are generated, create event timings, append to td class and populate even t frame
            if nevents > 0:
                # print("potential: %0.4f , %d events at location %d, %d" % (gc_in_,nevents, x, y))
                ts = self.gen_times(nevents)
        
                for t in np.nditer(ts):
                    event_ = {}
                    event_['x'] = x
                    event_['y'] = y
                    event_['p'] = pol
                    event_['ts'] = t
                
                    # self.td.data.append(event_)
                    events.append(event_)

                if pol > 0:
                    eframe[y,x] += nevents
                else:
                    eframe[y,x] -= nevents
        
        return eframe, events
            
    """
    generate temporal response
    """
    def get_tau(self, arr, minval):
        zz = arr/np.max(arr)
        return np.maximum(zz, minval)

    """
    generate number of events give difference in potential and given thresholds
    """
    def gen_events(self, thresholds, vmem):

        # create 2 element list with number events using on and off threshold
        # for a negative change, the negative index [1] will result in a postive number of events
        # for a positive change, the positive index [0] will ""
        # decide polarity by finding INDEX of positive number of events

        try:
            nev = [int(vmem//threshold) for threshold in thresholds] 
        except:
            nev = [0, 0]

        match = [1 if nev_ >= 0 else 0 for nev_ in nev]
        match_idx = match.index(1)

        nev_ = nev[match_idx]
        pol = 1 if match_idx == 0 else 0

        # if vmem >0:
        #     nev = int(vmem//thresholds[0])
            
        # else:
        #     nev = int(abs(vmem)//thresholds[1])

        # if nev > 0:

        return nev_, pol

    """
    generate event timings
    """
    def gen_times(self, nevents, dt=None, curt=None):

        if dt == None:
            dt = self.dt

        if curt == None:
            curt = self.t

        if nevents == 1:
            ts = self.t + self.dt//2
            ts += np.random.normal(0,(1/100)*self.dt)
        else:
            ts = np.arange(self.t, self.t + self.dt, self.dt/nevents)
            ts += np.random.normal(0,(1/100)*self.dt,ts.shape)

        ts *= 1e6

        return np.uint32(ts)
        
    # def change_thresh_mean(self,thr, pol = 'ON'):
    # def change_thresh_var(self,thr, pol = 'ON'):

"""
Algorithm
1. Init at 0 charge, have mean leakage rate with variance due to mismatch
2. Generate Events in image using model OR can use bipolar outputs
3. Add events to put charge into charge array
4. Compare charge array to global threshold to generate a binary image
5. Use local processing patch and function to filter and process image
6. Output events that are still one after processing and timestamp
7. Leak charge array
"""
class ProcessingLayerModel(RetinaNvsModel):
    name = 'ProcessingLayerModel'

    def __init__(self, 
                thr = [0.25,0.25], 
                thr_var = 2.5,
                roic_leakage_rate = 0,
                enable_diffusive_net = False, 
                show_frame = False, 
                fps = 100, 
                im_dim = (720,1280), 
                isprint = False):


        super().__init__(thr, thr_var, roic_leakage_rate, enable_diffusive_net, show_frame, fps, im_dim, isprint)

        self.charge = np.zeros((im_dim[0:2]))

        
        self.__charge_params = {}
        self.__charge_params['max_v'] = 1.0
        self.__charge_params['min_v'] = 0
        self.__charge_params['acc_p_event'] = 0.25
        self.__charge_params['time_constant'] = 0.1

        self.binary_threshold = 0.3

    
    def __call__(self, frames):

        f = 0
        bframes = []
        # Check if it is a stream of frames or a single frame
        try:
            assert(frames[0].shape[0] == self.im_dim[0])
        except: # Create list with single element
            frames = [frames]

        for frame in frames:
            if frame.shape[1] != self.im_dim[1]:
                frame = frames

            if self.isprint:
                print("Frame: %d" % (f))
                print("Time: %0.4f seconds" % (self.t))

            # pframe = self.pframe # already spatially and temporally filtered from last iteration
            
            if len(frame.shape) == 3:
                yframe = 0.29 * frame[:,:,0] + 0.58 * frame[:,:,1] + 0.114 * frame[:,:,2]
            else:
                yframe = frame

            if not self.f_frame:
                t0 = time.time()
                # photoreceptor layer
                pr_past, pr_cur = self.photoreceptor(yframe)
                # bipolar layer
                bc = self.bipolar(pr_cur,pr_past)
                # ganglion layer
                eframe, events = self.ganglion(bc, self.vmem)
                eframe -= 128
                # store update bipolar potential
                self.vmem = bc
                # # add charge to charge events
                self.add_charge(abs(eframe))
                self.decay_charge(mode = 'linear')

                bframe = self.binarize(self.binary_threshold)

                mframe = self.morpho_1bit(bframe)
                # bframes.append(abs(eframe))
                # bframes.append(self.charge)
                bframes.append(bframe)

                t3 = time.time()

                if self.isprint:
                    print("Full Model took %s seconds" % ((t3-t0)))
              
            else:
                self.f_frame = False
                events = {}

            # shift values
            self.ppframe = self.pframe
            self.pframe = yframe
            # increment global time
            self.t += self.dt
            f += 1
            if self.isprint:
                print("Number of events: %d" %(len(self.td.data)))

        return bframes

    """
    visualize charge surfaces
    """
    def visualize_charge(self, roi = (0,0,63,63), show_frame=False):
        img = np.uint8(self.charge[roi[0]:roi[2],roi[1]:roi[3]])
        if show_frame:
                cur = np.flipud(img)
                cv2.namedWindow('Frame',cv2.WINDOW_NORMAL)
                cv2.resizeWindow('Frame', 600,600)
                cv2.imshow('Frame', cur)
                cv2.waitKey(0)
        return img

    """
    maintain charge array
    """
    def add_charge(self,eframe):
        self.charge += self.__charge_params['acc_p_event']*eframe
        self.charge = np.minimum(self.charge,self.__charge_params['max_v'])

    def decay_charge(self, mode = 'exponential'):
        dcharge = self.__charge_params['max_v'] - self.charge
        if mode == 'exponential':
            self.charge = np.exp(-1*dcharge/self.__charge_params['time_constant'])
        elif mode == 'linear':
            self.charge -= self.__charge_params['time_constant']
            self.charge = np.maximum(self.charge, self.__charge_params['min_v'])

    def binarize(self,threshold):
        bframe = np.zeros(self.charge.shape, dtype = np.uint8)
        bframe[self.charge > threshold] = 1
        return bframe


    def morpho_1bit(self, bin_im, structuring_element=[1,1,1,1,1,1,1,1,1], function_in=[0,0,1,1,1,1,1,1,1,1]):
        roi_list = []

        bin_im_pad = np.pad(bin_im, ((1, 1), (1, 1)), 'wrap') ## padding
        for rix in range(1,bin_im_pad.shape[0]-1):
            for cix in range(1,bin_im_pad.shape[1]-1):
                roi = bin_im_pad[rix-1:rix+1, cix-1:cix+1]
                roi_single_list = [el for row in roi for el in row]
                roi_list.append(roi_single_list)
        

        sum_result = [sum(x_i * se_i for x_i, se_i in zip(x_sublist, structuring_element)) for x_sublist in roi_list]
        morpho_result =  [function_in[ii] for ii in sum_result]

        return np.reshape(morpho_result, (bin_im.shape[0],bin_im.shape[1]))

def file2frames(filepath = './tmp/kk.avi', im_dim = None, num_frames = None, isrgb = True, isshow = False):

    print("File: %s" % filepath)
    cap = cv2.VideoCapture(filepath)

    frames = []
    f = 0
    while True:
        ret, frame = cap.read()
        if not isrgb: 
            try:
                frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            except:
                break
        if im_dim != None:
            try:
                frame = cv2.resize(frame, im_dim) 
            except:
                break
        if isshow:
            try:
                cv2.imshow('frame',frame)
                if cv2.waitKey(10) & 0xFF == ord('q'):
                    break
                cv2.waitKey(25)
            except:
                break
        frames.append(frame)

        if not ret:
            break

        f += 1
        if (num_frames != None) and (f == num_frames):
            break

    cap.release()
    cv2.destroyAllWindows()

    try:
        print("Number of frames: %d, Size of frame: %d x %d x %d" % (len(frames), frames[0].shape[0], frames[0].shape[1], frames[0].shape[2]))
    except:
        print("Number of frames: %d, Size of frame: %d x %d" % (len(frames), frames[0].shape[0], frames[0].shape[1]))

    return frames


def retina_main():
    #Load Video
    frames = file2frames(filepath='/Users/jonahs/Documents/research/projects/spike_proc/data/video/simp_ball/simp_ball_3.avi', isshow= True, im_dim=(64,64), isrgb=True)

    # Initialize Model
    nvs_model = RetinaNvsModel(isprint = True, im_dim=(frames[0].shape[0],frames[0].shape[1]), thr = [0.5, 0.5],  thr_var=0, fps = 240, leakage_rate=0)
    # Run Whole Video Through Model
    nvs_model(frames)
    # # Visualize Model Output
    nvs_model.td.events2frames(show_frame=True, method= 'time', isflip=False, bin_param=(1/240)*1e6)

    # Process Frame by Frame
    nvs_model_ = RetinaNvsModel(im_dim=(frames[0].shape[0],frames[0].shape[1]), thr_var=0, fps = 240, leakage_rate=0, isprint=True)
    for frame in frames:
        nvs_model_(frame)
    # Visualize Model Output
    nvs_model_.td.events2frames(show_frame=True, method= 'time', isflip=False, bin_param=(1/240)*1e6)

def layer_main():
    #Load Video
    frames = file2frames(filepath='/Users/jonahs/Documents/research/projects/spike_proc/data/video/simp_ball/simp_ball_4.avi', isshow= False, im_dim=(180,240), num_frames= 100, isrgb=True)

    # Initialize Model
    proc_model = ProcessingLayerModel(im_dim=(frames[0].shape[0],frames[0].shape[1]), thr_var=0.7, fps = 240, roic_leakage_rate=10)

    bframes = proc_model(frames)

    for bframe in bframes:
        bframe *= 255

        cv2.namedWindow('Frame',cv2.WINDOW_NORMAL)
        cv2.resizeWindow('Frame', 600,600)
        cv2.imshow('Frame', np.uint8(bframe))
        cv2.waitKey(0)


if __name__ == "__main__":
    retina_main()

    
print("Import of JHU Retinal Model module is successful!")