function [ index_elimi,RecClockPre,RecClockBias,Innovation,RecClockRateBias] = RemoveOutlierGNSSObs( RecPosi,RecVelo,GNSSObs,est_clock_previous,tor_s,RecClockPreprocOptions,GNSS_config )
%�޳����ǡ�����Ȳ���������Ҫ��Ĺ۲�
%��ִ�ж�λ����֮ǰ��ͨ������Ľ��ջ�λ�÷�����ջ����Ӳÿ��α��۲ⶼ�ܹ��õ�һ���Ӳ�ֵ
%�Ը����Ӳ����λ����ΪԤ���Ľ��ջ��Ӳ�RecClockPre
%��ĳ�����ǽ���õ����Ӳ���RecClockPre����(�ò��켴ʹ��RecClockPre��Ϊ�Ӳ���㵽����Ϣ)����RecClockBiasThreshold���޳�
%RecClockPreprocOptions=2ʱRecClockBias��Innovation��ȣ�RecClockPreprocOptions=0ʱ����Innovationʹ�õĽ��ջ��Ӳ���ͨ��һ�����Ƶõ���
% Inputs:
% RecPosi           �����GNSS���ջ�����λ��
% RecVelo           ������ջ��ٶ�
% GNSSObs           Ԥ������GNSS�۲�����
%  Column 1: epoch
%  Column 2: Obsweek (week)
%  Column 3: Obssec (s)
%  Column 4: PRN
%  Column 5: Ionospheric Free pseudorange linear combination (m)
%  Column 6: slant tropospheric delay (m)
%  Column 7: Satellite clock error (s)
%  Column 8: relativity correction (m)
%  Column 9-11: Satellite position in ECEF(m)
%  Column 12: range rate(m/s)
%  Column 13: Rate of Satellite clock  (s/s)
%  Column 14-16: Satellite velocity in ECEF(m/s)
%  Column 17: flag= 0 means this PRN was Removed in  GNSS Single point Navigation Solution
%  Column 18: Elevation angle (deg)
%  Column 19: Azimuth (deg)
%  Column 20: user ranging error  (m)
%  Column 21: residual (m)
%  Column 22: a priori Pseudo-distance noise standard deviation (m)
% est_clock_previous            ��һ��Kalman�˲��õ��Ľ��ջ��Ӳ�����
%  Column 1: ���ջ��Ӳ�����Ĳ����� ��m��
%  Column 2: ���ջ����� ��m/s��
% tor_s  Time interval��s��
% RecClockPreprocOptions        0��ʾȫ��ʹ�ô�ͳģ�� 2��ʾȫ��ʹ���Ӳ���Ԥ���������� 
% GNSS_config
%     .epoch_interval     Interval between GNSS epochs (s)
%     .init_est_r_ea_e    Initial estimated position (m; ECEF)
%     .mask_angle         Mask angle (deg)
%     .mask_SignalStrenth Mask Carrier to noise ratio(dbhz)
%     .rx_clock_offset    Receiver clock offset at time=0 (m)
%     .rx_clock_drift     Receiver clock drift at time=0 (m/s)
%     .intend_no_GNSS_meas       �ɴ����GNSS���������ޣ��۲��������ڸ�ֵ�������ǲ���
% Outputs:
% RecClockPre ������ջ��Ӳ�����Ĳ����m��
% index_elimi ��������0��ʾ������1��ʾ�޳����ǣ�����������GNSSObs�����ж�Ӧ
% RecClockBias �����Ǽ���õ��Ľ��ջ��Ӳ���RecClockPre�Ĳ���
% RecClockRateBias �����Ǽ���õ��Ľ��ջ�������RecClockPre�Ĳ���
% Innovation ��Ϣ ����Ϊ�۲���Ŀ��2�����ϰ벿��Ϊα����Ϣ���°벿��Ϊα������Ϣ
c=299792458.0;   % velocity of light (m/s)
RecClockBiasThreshold=30;
InnovationThreshold=30;
[no_GNSS_meas,~]=size(GNSSObs);
% ����Ԥ����α��
RecClockPre=median(GNSSObs(:,5)-GNSSObs(:,6)+GNSSObs(:,7)*c+GNSSObs(:,8)-...
     sqrt(dot(GNSSObs(:,9:11)'-RecPosi*ones(1,no_GNSS_meas),GNSSObs(:,9:11)'-RecPosi*ones(1,no_GNSS_meas)))');
%  ����Ԥ����α���� ����Sagnac
u_as_e_T = zeros(no_GNSS_meas,3);
RecClockRateAll =zeros(no_GNSS_meas,1);
for i=1:no_GNSS_meas
    delta_r =  GNSSObs(i,9:11)' - RecPosi; 
    range = sqrt(delta_r' * delta_r);
    u_as_e_T(i,1:3) = delta_r' / range;
    RecClockRateAll(i,1)= GNSSObs(i,12)-u_as_e_T(i,1:3) * (GNSSObs(i,14:16)'- RecVelo);
end
RecClockRatePre=median(RecClockRateAll); 
RecClockBias=GNSSObs(:,5)-GNSSObs(:,6)+GNSSObs(:,7)*c+GNSSObs(:,8)-...
     sqrt(dot(GNSSObs(:,9:11)'-RecPosi*ones(1,no_GNSS_meas),GNSSObs(:,9:11)'-RecPosi*ones(1,no_GNSS_meas)))'-RecClockPre;
RecClockRateBias= RecClockRateAll-RecClockRatePre;
if RecClockPreprocOptions==0
    RecClockUpdate=est_clock_previous(1)+est_clock_previous(2)*tor_s;
    Innovation=[GNSSObs(:,5)-GNSSObs(:,6)+GNSSObs(:,7)*c+GNSSObs(:,8)-...
        sqrt(dot(GNSSObs(:,9:11)'-RecPosi*ones(1,no_GNSS_meas),GNSSObs(:,9:11)'-RecPosi*ones(1,no_GNSS_meas)))'-RecClockUpdate*ones(no_GNSS_meas,1);...
        RecClockRateAll-est_clock_previous(2)*ones(no_GNSS_meas,1)];
    index_elimi=abs (Innovation(1:no_GNSS_meas))>InnovationThreshold;
else
    Innovation=[RecClockBias;RecClockRateBias];
    index_elimi=abs (RecClockBias)>RecClockBiasThreshold;
end
index_lowele=GNSSObs(:,18)<GNSS_config.mask_angle;
index_lowSignalStrenth=GNSSObs(:,23)<GNSS_config.mask_SignalStrenth|GNSSObs(:,24)<GNSS_config.mask_SignalStrenth;
index_elimi=index_lowele|index_lowSignalStrenth|index_elimi;
end

