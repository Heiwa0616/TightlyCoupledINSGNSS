%INS_GNSS_Demo_7
%SCRIPT Tightly coupled INS/GNSS demo:
%   
%   Consumer-grade IMU
%
% Software for use with "Principles of GNSS, Inertial, and Multisensor
% Integrated Navigation Systems," Second Edition.
%
% Created 12/4/12 by Paul Groves

% Copyright 2012, Paul Groves
% License: BSD; see license.txt for details
% Modified 2017/8 by LiuXiao BUAA benzenemo@buaa.edu.cn % 20170311B104ZXY
clc
clear
% Constants
deg_to_rad = 0.01745329252;
rad_to_deg = 1/deg_to_rad;

micro_g_to_meters_per_second_squared = 9.80665E-6;
global STA
load('..\SharedMat\MOD_constant')
load('..\SharedMat\MOD_STA_BUAADF_RTK')
% load('..\SharedMat\MOD_STA')%����2017106���ݵ�ˮƽ����ϵԭ��
% CONFIGURATION
% Output motion profile and error filenames
output_profile_name = ['INS_GNSS_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
out_IMU_bias_est_name=['IMU_bias_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
out_clock_name=['Clock_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
out_KF_SD_name=['KF_SD_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
PickSubsetRes_name=['PickSubsetRes_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
RecClockBiasRes_name=['RecClockBiasRes_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
out_MeasurementNoise_SD_name=['MeasurementNoise_SD_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
out_Resi_name=['Resi_StdResi_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
out_Inno_name=['Inno_' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
out_StdInno_name=['Std_Inno' datestr(now,'yyyy-mm-dd-HH-MM') '.mat'];
% output_errors_name = 'INS_GNSS_Demo_7_Errors.csv';

% Interval between GNSS epochs (s)
GNSS_config.epoch_interval = 1.0;
% Max Number of satellites
GNSS_config.intend_no_GNSS_meas = 30;%If the number of observations exceeds this value, start satellite screening
% Mask angle (deg)
GNSS_config.mask_angle = 10;
% Mask Carrier to noise ratio(dbhz)
GNSS_config.mask_SignalStrenth = 30;
% Inner System Bias(m)
% GNSS_config.ISBBDS_GPS = 59.5*c/1e9;%2018206 ClockBDS-ClockGPS
GNSS_config.ISBBDS_GPS = 69.13*c/1e9;%2018165 ClockBDS-ClockGPS
% Satellite to Omit
GNSS_config.omit = 33:56;%Control the GNSS type involved in the solution through this configuration
% GNSS type and PRN mapping list
GNSS_config.GPSPRNList=1:32;
GNSS_config.GLONASSPRNList=33:56;
GNSS_config.BDSPRNList=57:91;

% Initial attitude uncertainty per axis (deg, converted to rad)
TC_KF_config.init_att_unc = degtorad(20);
% Initial velocity uncertainty per axis (m/s)
TC_KF_config.init_vel_unc = 0.1;
% Initial position uncertainty per axis (m)
TC_KF_config.init_pos_unc = 10;
% Initial accelerometer bias uncertainty per instrument (micro-g, converted
% to m/s^2)
TC_KF_config.init_b_a_unc = 10000 * micro_g_to_meters_per_second_squared;
% Initial gyro bias uncertainty per instrument (deg/hour, converted to rad/sec)
TC_KF_config.init_b_g_unc = 10 * deg_to_rad / 3600;
% Initial clock offset uncertainty per axis (m)
TC_KF_config.init_clock_offset_unc = 10;
% Initial clock drift uncertainty per axis (m/s)
TC_KF_config.init_clock_drift_unc = 0.1;

% Gyro noise PSD (deg^2 per hour, converted to rad^2/s)                
TC_KF_config.gyro_noise_PSD = (0.01)^2;
% Accelerometer noise PSD (micro-g^2 per Hz, converted to m^2 s^-3)                
TC_KF_config.accel_noise_PSD = (0.1)^2;

% NOTE: A large noise PSD is modeled to account for the scale-factor and
% cross-coupling errors that are not directly included in the Kalman filter
% model
% Accelerometer bias random walk PSD (m^2 s^-5)
TC_KF_config.accel_bias_PSD = 1.0E-5;
% Gyro bias random walk PSD (rad^2 s^-3)
TC_KF_config.gyro_bias_PSD = 4.0E-11;
% Receiver clock frequency-drift PSD (m^2/s^3)
TC_KF_config.clock_freq_PSD = 1;
% Receiver clock phase-drift PSD (m^2/s)
TC_KF_config.clock_phase_PSD = 1;
% Pseudo-range measurement noise SD (m)
TC_KF_config.pseudo_range_SD = 2.5;
% Pseudo-range rate measurement noise SD (m/s)
TC_KF_config.range_rate_SD = 0.1;

TC_KF_config.RecClockPreprocOptions=0;% The default value is 0,If the receiver clock jitter, the value is 2

TC_KF_config.KFMethod='ClassicKF';%ClassicKF means using the classic Kalman filter,M-LSKFClassicKF means using the classic Kalman filter,��IAE-KF��ʾʹ����Ϣ��R���������
TC_KF_config.StationarityDetectionInterval=1;
TC_KF_config.StationarityDetectionFlag=[0,0,0,0];%����Ԫ��Ϊ0��ʾ����⣬1��ʾ����ĳ���͵ļ�⣬Ԫ�ض�Ӧ�ļ�ⷽ������Ϊ[ˮƽ�ٶ���ֵ��� ���ٶȼƲ�����׼�� Ƶ���˲��� ��λ������]
if TC_KF_config.StationarityDetectionFlag(1)==1
    TC_KF_config.StationarityDetectionHorizontalSpeed=0.5;%��ֹ���ˮƽ�ٶ���ֵ��m/s
    TC_KF_config.StationarityDetectionHSTimeWindow=10;%ˮƽ�ٶȼ��ʱ�䴰�ڣ�s
end
if TC_KF_config.StationarityDetectionFlag(2)==1
    TC_KF_config.StationarityDetectionAccelerometerStd=0.01;%��ֹ���ǰ����ٶȼƱ�׼����ֵ��m/s-2
    TC_KF_config.StationarityDetectionHSTimeWindow=10;%��׼����ʱ�䴰�ڣ�s
end
%�������У���������ݹ۲�ֵ�Ĺ۲�����SD��rad/s��
TC_KF_config.ZARU_DGrySD=0.00050;

%˫GNSS���߹۲�����
TC_KF_config.DoubleGNSSFlag=1;%1��ʾ��˫GNSS���߲�������

%% �ṩ��ʼλ���ٶ���̬
load('..\TCdata\GNSSObsForCouple\2018\165\С��\GNSSRes2018-06-28-21-16')
% old_time=269800;%2018206�տ���ʵ���ʼ��׼���ʱ��
old_time=379800;%2018165��Сʵ���ʼ��׼���ʱ��
% old_time=34546.104;%2017106�������ܳ����ʼ��׼���ʱ��
index_ini=find(GNSSRes.sow==floor(old_time));
old_est_r_ea_e=[GNSSRes.x(index_ini);GNSSRes.y(index_ini);GNSSRes.z(index_ini)];%��ʼGNSS����λ��
old_est_v_ea_e=[GNSSRes.vx(index_ini);GNSSRes.vy(index_ini);GNSSRes.vz(index_ini)];%��ʼGNSS�ٶ�
est_clock=[GNSSRes.RecClk(index_ini)*c, GNSSRes.RecClockDrift(index_ini)*c];
%��ʼ��̬��,roll, pitch, yaw���ο�ϵ������תyaw��pitch��roll���˶�ϵ
% attitude_ini=[0.206;-0.099;-178.795]*pi/180;%2018206�տ���ʵ����̬�ǳ�ʼ��׼���
attitude_ini=[-0.380;0.118;-128.069]*pi/180;%2018165��Сʵ����̬�ǳ�ʼ��׼���
% attitude_ini=[-0.657;-0.623;-153.994]*pi/180;%2017106��������̬�ǳ�ʼ��׼���
% L_ba_b=[0.30;-0.25;-1.00];%2017106�����ܳ�ʵ���Ħ����HiGNSS���ߵ���֪�˱� ǰ����
L_ba_b=[-0.055;-0.275;-0.144];%2018��165��206�� С��ʵ�鿨��ʵ�� SPANIMU��1�����ߵĸ˱� ǰ����
% L_ba_b=[0.00;-0.41;-1.38];%2017265��С��ʵ��ĸ˱�
old_est_C_b_n=Euler_to_CTM(attitude_ini)';%��IMU��ϵ������ˮƽ����ϵ����ת������
[old_est_L_a,old_est_lambda_a,old_est_h_a,old_est_v_ea_n] =...
    pv_ECEF_to_NED(old_est_r_ea_e,old_est_v_ea_e);
[~,~,old_est_C_b_e] = NED_to_ECEF(old_est_L_a,...
    old_est_lambda_a,old_est_h_a,old_est_v_ea_n,old_est_C_b_n);
old_est_r_eb_e=old_est_r_ea_e-old_est_C_b_e*L_ba_b;
old_est_v_eb_e=old_est_v_ea_e;%�ٶȵĸ˱�ЧӦ�˴�����
Total_GNSS_epoch=length(GNSSRes.sow);
FilePath.GNSSFile='..\TCdata\GNSSObsForCouple\2018\165\С��\GNSSObsForCouple2018-06-28-21-16.mat';
FilePath.INSFile='..\TCdata\IMU\2018\165\SPANIMU2018165.mat';
if TC_KF_config.DoubleGNSSFlag==1
    FilePath.DoubleGNSSHeadingFile='..\TCdata\SPANE1\2018\165\С��\DoubleGNSSHeading.mat';%�ļ��еĺ���ΪGNSS����1ָ��GNSS����2�������ĺ���
    L_ba_b_GNSS2=[0.018;0.206;-0.099];%%2018��165��206�� С��ʵ�� SPANIMU��2�����ߵĸ˱� ǰ����
    TC_KF_config.HeadingBias=atan((L_ba_b(2)-L_ba_b_GNSS2(2))/(L_ba_b(1)-L_ba_b_GNSS2(1)));%GNSSHeading-IMUHeading
end
% Tightly coupled ECEF Inertial navigation and GNSS integrated navigation
[out_profile,out_IMU_bias_est,out_clock,out_KF_SD,PickSubsetRes,RecClockBiasRes,...
    out_MeasurementNoise_SD,out_Resi,InnovationRes,StdInnovationRes] =...
    Tightly_coupled_INS_GNSS(FilePath,old_time,old_est_r_eb_e,old_est_v_eb_e,...
    est_clock,attitude_ini,GNSS_config,TC_KF_config,L_ba_b,Total_GNSS_epoch);
% Plot the input motion profile and the errors (may not work in Octave).
close all;
save(output_profile_name,'out_profile')
save(out_IMU_bias_est_name,'out_IMU_bias_est')
save(out_clock_name,'out_clock')
save(out_KF_SD_name,'out_KF_SD')
save(PickSubsetRes_name,'PickSubsetRes')
save(RecClockBiasRes_name,'RecClockBiasRes')
save(out_MeasurementNoise_SD_name,'out_MeasurementNoise_SD')
if strcmp(TC_KF_config.KFMethod,'M-LSKF')
    save(out_Resi_name,'out_Resi')
end
save(out_Inno_name,'InnovationRes')
if strcmp(TC_KF_config.KFMethod,'IAE-KF')
    save(out_StdInno_name,'StdInnovationRes')
end
% Ends