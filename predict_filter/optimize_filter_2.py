#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import argparse
import time
import sys
import os


# Data paths
PATH_SKYNET = "/home/skynet/Desktop/datos_liset/"
PATH_ROY = "sessions/"
PATH_ANDREA = "/home/andrea/DATA/"
PATH_PLATON = "/home/andrea/proyecto_ripples/data/"
PATH_ARTEMISA = "/lustre/ific.uv.es/ml/ic028/"


#   -------------------------
# 	| 	DEFINE PARAMETERS 	|
#   -------------------------

# - Database default variables
list_sessions_default = [551, 552]



# Possible arguments and details
ap = argparse.ArgumentParser()
ap.add_argument("-U", "--user", required=False, default='Roy')
ap.add_argument("-Z", "--normalize", required=False, default=True)
ap.add_argument("-S", "--list_sessions", required=False, default=list_sessions_default)
ap.add_argument("-K", "--selected_shank", required=False, default=-1)
args = vars(ap.parse_args())



# Definition of variables
# - Possible arguments and details
user = args['user']


# - Database default variables
if type(args["list_sessions"])==list:
	list_sessions = args["list_sessions"]
else:
	if '-' in args["list_sessions"]:
		list_sessions = list(range(int(args["list_sessions"].split('-')[0]), int(args["list_sessions"].split('-')[1])))
	else:
		list_sessions = [int(i) for i in args["list_sessions"].split(',')]


selected_shank = int(args['selected_shank'])
normalize = bool(int(args['normalize']))




print('Experiment name')
print('\t -- user = ',user)
print('\t -- normalize = ',normalize)
print('\t -- list_sessions = ',list_sessions)
print('\t -- selected_shank = ',selected_shank)


sys.path.insert(1, 'proyecto_ripples/analysis/python_analysis_tools/load_functions')
import load_events
import load_open_ephys
import load_auxiliar

sys.path.insert(1, 'proyecto_ripples/analysis/python_analysis_tools/metrics')
import metrics

sys.path.insert(1, 'proyecto_ripples/analysis/python_analysis_tools/discovery')
import event_properties


sys.path.insert(1, 'proyecto_ripples/scripts/')
import load_data



# Set global path
PATH = PATH_ANDREA if (user=='Andrea') else PATH_ROY
if user=='Platon': PATH = PATH_PLATON
if user=='skynet': PATH = PATH_SKYNET
if user=='ic0283' or user=='ic0282': PATH = PATH_ARTEMISA

# Get session path
with open('proyecto_ripples/scripts/sessions.txt','r') as file: 
	PATH_SESSIONS = [line[:-1] for line in file]


downsampled_fs = 30000

# Load database
session_path = "sessions/Kilosort/Amigo2_1/hippo_2019-07-11_11-57-07_1150um_re_tag"
print("Loading session %s..."%(session_path))
fs, expName, ripples, channels_map, channels, shanks, dead_channels, ref_channels, data = load_data.load_data(session_path, load_dat=True, verbose=False)


# Get shank with more ripples if not provided
if selected_shank == -1:
	selected_shank = load_auxiliar.get_shank_with_max_events(ripples)

pyr_channel = int(ref_channels['pyr'][selected_shank-1])


# Get only ripples in selected shank and convert to seconds
ripples_in_shank_idx = np.argwhere(ripples[:, 4] == selected_shank).flatten()
ripples_in_shank = ripples[ripples_in_shank_idx, :]
true_events_1 = ripples_in_shank[:, [0,2]] / fs

# Pyramidal LFP
pyr = data[:, pyr_channel]

if normalize:
	# Normalized data
	pyr_norm_1 = (pyr - np.mean(pyr, axis=0)) / np.std(pyr, axis=0)
else:
	pyr_norm_1 = pyr


data_1_offset = pyr_norm_1.shape[0]



pos_mat = list(range(data.shape[1]-1, -1, -1)) * np.ones((data.shape[0], data.shape[1]))

plt.plot(data[:, :]*1/np.max(data[:, :], axis=0) + pos_mat, color='k', linewidth=1)
plt.show()





session_path = "sessions/Kilosort/Som_2/hippo_2019-07-24_12-01-49_1530um_re_tag"
print("Loading session %s..."%(session_path))
fs, expName, ripples, channels_map, channels, shanks, dead_channels, ref_channels, data = load_data.load_data(session_path, load_dat=True, verbose=False)


# Get shank with more ripples if not provided
if selected_shank == -1:
	selected_shank = load_auxiliar.get_shank_with_max_events(ripples)

pyr_channel = int(ref_channels['pyr'][selected_shank-1])

# Get only ripples in selected shank and convert to seconds
ripples_in_shank_idx = np.argwhere(ripples[:, 4] == selected_shank).flatten()
ripples_in_shank = ripples[ripples_in_shank_idx, :]
true_events_2 = ripples_in_shank[:, [0,2]] / fs


# Pyramidal LFP
pyr = data[:, pyr_channel]

if normalize:
	# Normalized data
	pyr_norm_2 = (pyr - np.mean(pyr, axis=0)) / np.std(pyr, axis=0)
else:
	pyr_norm_2 = pyr


pos_mat = list(range(data.shape[1]-1, -1, -1)) * np.ones((data.shape[0], data.shape[1]))

plt.plot(data[:, :]*1/np.max(data[:, :], axis=0) + pos_mat, color='k', linewidth=1)
plt.show()


# Merge sessions
pyr_norm = np.concatenate((pyr_norm_1, pyr_norm_2), axis=0)

true_events = np.concatenate((true_events_1, true_events_2 + (data_1_offset / downsampled_fs)), axis=0)




print(pyr_norm.shape)
print(true_events.shape)

plt.plot(pyr_norm)
plt.plot(data_1_offset, 1, "o")
plt.show()




# Parameters to test
orders = range(1, 11)
low_cuts = [80, 90, 100]
high_cuts = [250, 300]



fid = open("filter_params_sweep_30k.txt", "w")


for i_order, order in enumerate(orders):
	for i_low_cut, low_cut in enumerate(low_cuts):
		for i_high_cut, high_cut in enumerate(high_cuts):

			print("TESTING: %d order band-pass (%d - %d Hz) filter"%(order, low_cut, high_cut))

			# Get filtered and envelope signal
			pyr_filtered, pyr_envelope = event_properties.compute_filter_and_envelope(pyr_norm, downsampled_fs, lowcut=low_cut, highcut=high_cut, order=order)

			# Compute position and maximum power
			middles, minimums, amplitudes = event_properties.middle_minimum_amplitude(true_events, pyr_norm, pyr_envelope, downsampled_fs, verbose=True)


			# Compute std
			thr_std = np.nanstd(pyr_envelope)



			# Get predictions for different threshold combinations
			thrs1 = np.arange(1, 3, 0.5)
			thrs2 = np.arange(2, 10.5, 0.5)

			#thrs1 = np.array([2.5])
			#thrs2 = np.array([2.5, 3., 3.5, 4., 4.5, 5., 6., 6.5, 7.])

			F1s = np.zeros((thrs1.shape[0], thrs2.shape[0]))


			for i_low_t, low_t in enumerate(thrs1):
				for i_high_t, high_t in enumerate(thrs2):

					# We get events over high threshold
					events_times_high = np.zeros((0,2), dtype=int)

					# Get the times (in points) where the signals cross the threshold
					mask_pred = np.diff(1 * (pyr_envelope >= (thr_std * high_t)) != 0)
					preds_envelope = np.argwhere(mask_pred == True).flatten()


					envelope_directions = pyr_envelope[preds_envelope] - pyr_envelope[preds_envelope+1]
					# Get the intervals starting and ending times
					pred_inis = preds_envelope[envelope_directions < 0]
					pred_ends = preds_envelope[envelope_directions > 0]


					# Discard unmatched inis or ends
					if len(pred_ends) < len(pred_inis):
						# If there is one more ini than end
						pred_ends = np.append(pred_ends, pts_per_chunk-1)
					elif len(pred_ends) > len(pred_inis):
						# If there is one more end than ini
						pred_inis = np.insert(pred_inis, 0, 0)
					


					# Make a (# events)x2 array
					pred_inis = np.reshape(pred_inis, (-1, 1))
					pred_ends = np.reshape(pred_ends, (-1, 1))
					iniend = np.append(pred_inis, pred_ends, axis=1)


					events_times_high = np.concatenate([events_times_high, iniend], axis=0)



					# We get events over low threshold
					events_times_low = np.zeros((0,2), dtype=int)

					# Get the times (in points) where the signals cross the threshold
					mask_pred = np.diff(1 * (pyr_envelope >= (thr_std * low_t)) != 0)
					preds_envelope = np.argwhere(mask_pred == True).flatten()


					envelope_directions = pyr_envelope[preds_envelope] - pyr_envelope[preds_envelope+1]
					# Get the intervals starting and ending times
					pred_inis = preds_envelope[envelope_directions < 0]
					pred_ends = preds_envelope[envelope_directions > 0]


					# Discard unmatched inis or ends
					if len(pred_ends) < len(pred_inis):
						# If there is one more ini than end
						pred_ends = np.append(pred_ends, pts_per_chunk-1)
					elif len(pred_ends) > len(pred_inis):
						# If there is one more end than ini
						pred_inis = np.insert(pred_inis, 0, 0)
					


					# Make a (# events)x2 array
					pred_inis = np.reshape(pred_inis, (-1, 1))
					pred_ends = np.reshape(pred_ends, (-1, 1))
					iniend = np.append(pred_inis, pred_ends, axis=1)


					events_times_low = np.concatenate([events_times_low, iniend], axis=0)



					# We get low events that have a match with high events	
					events_times = []

					for low_event in events_times_low:
						for high_event in events_times_high:
							if (low_event[0] <= high_event[0]) and (low_event[1] >= high_event[1]):
								events_times.append(low_event)


					events_times = np.array(events_times) / downsampled_fs # To seconds


					# Calculate metrics
					precision_new, recall_new, F1_new, true_positives_new, false_negatives_new, correlation_new, lags_ms_new, lags_middles_new, mean_lag_ms_new, mean_lag_middles_new, mean_lag_per_delay_new, mean_lag_per_t2p_new = metrics.relate_true_pred(true_events, events_times, middles, minimums, separation=0.016, verbose=False)

					if not np.isnan(mean_lag_ms_new):
						F1s[i_low_t, i_high_t] = F1_new


			max_F1 = np.nanmax(F1s)
			max_low_t = thrs1[np.where(F1s == np.nanmax(F1s))[0][0]]
			max_high_t = thrs2[np.where(F1s == np.nanmax(F1s))[1][0]]


			print("F1: %.2f Low thresh: %.2f High thresh: %.2f\n"%(max_F1, max_low_t, max_high_t))


			fid.write("%d %d %d %.2f %.2f %.2f\n"%(order, low_cut, high_cut, max_F1, max_low_t, max_high_t))


fid.close()