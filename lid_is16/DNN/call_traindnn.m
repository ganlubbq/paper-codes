 %{
###########################################################################
##                                                                       ##
##                                                                       ##
##                       IIIT Hyderabad, India                           ##
##                      Copyright (c) 2015                               ##
##                        All Rights Reserved.                           ##
##                                                                       ##
##  Permission is hereby granted, free of charge, to use and distribute  ##
##  this software and its documentation without restriction, including   ##
##  without limitation the rights to use, copy, modify, merge, publish,  ##
##  distribute, sublicense, and/or sell copies of this work, and to      ##
##  permit persons to whom this work is furnished to do so, subject to   ##
##  the following conditions:                                            ##
##   1. The code must retain the above copyright notice, this list of    ##
##      conditions and the following disclaimer.                         ##
##   2. Any modifications must be clearly marked as such.                ##
##   3. Original authors' names are not deleted.                         ##
##   4. The authors' names are not used to endorse or promote products   ##
##      derived from this software without specific prior written        ##
##      permission.                                                      ##
##                                                                       ##
##  IIIT HYDERABAD AND THE CONTRIBUTORS TO THIS WORK                     ##
##  DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING      ##
##  ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT   ##
##  SHALL IIIT HYDERABAD NOR THE CONTRIBUTORS BE LIABLE                  ##
##  FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    ##
##  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN   ##
##  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,          ##
##  ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF       ##
##  THIS SOFTWARE.                                                       ##
##                                                                       ##
###########################################################################
##                                                                       ##
##          Author :  Sivanand Achanta (sivanand.a@research.iiit.ac.in)  ##
##          Date   :  Jul. 2015                                          ##
##                                                                       ##
###########################################################################
%}
clear all; close all; clc;

% Load configuration file
config

% Step 1 : Read data
readdata_dnn

% Step 2 : Set architecture
arch_name1 = strcat(arch_name1,num2str(dout),ol_type);
arch_init

% set hyper params
switch sgd_type
    
    case 'sgdcm'
        
        % Training DNN using Naive SGD with classical momentum
        
        disp('training with SGD-CM optimizer ...\n');
        
        for l2 = l2_vec
            for lr = lr_vec
                for mf = mf_vec
                    
                    % Step 4 : Weight initialization
                    wt_init
                    
                    arch_name2 = strcat('_l2',num2str(l2),'_lr',num2str(lr),'_mf',num2str(mf),'_',wtinit_meth);
                    arch_name = strcat(arch_name1,arch_name2,'_',num2str(nwt))
                    
                    if gpu_flag
                        disp('training on GPU !!! :) ');
                        Gb = gpuArray(b);  GW = gpuArray(W);
                        Gpdb = gpuArray(zeros(size(b)));  GpdW = gpuArray(zeros(size(W)));
                    else
                        disp('training on CPU ... ');
                        Gb = b;  GW = W;
                        Gpdb = zeros(size(b));  GpdW = zeros(size(W));
                    end
                    
                    trainer
                    
                end
            end
            
        end
        
        
    case 'adadelta'
        
        % Training DNN using ADA-DELTA
        % Ref : ADADELTA: An Adaptive Learning Rate Method - Matthew Zeiler
        
        disp('training with ADA-DELTA optimizer ...');      
        
        for l2 = l2_vec
            for rho = rho_vec
                for eps = eps_vec
                    for mf = mf_vec
                        
                        % Step 4 : Weight initialization
                        wt_init
                        
                        arch_name2 = strcat('_l2',num2str(l2),'_rho',num2str(rho),'_eps',num2str(eps),'_mf',num2str(mf),'_',wtinit_meth);
                        arch_name = strcat(arch_name1,arch_name2,'_',num2str(nwt))
                        
                        if gpu_flag
                            disp('training on GPU ... :( ');
                            Gb = gpuArray(b);
                            GW = gpuArray(W);
                            Gpdb = gpuArray(zeros(size(b)));  GpdW = gpuArray(zeros(size(W)));
                            Gpmsgbt = gpuArray(zeros(1,btl(end)-1));  GpmsgWt = gpuArray(zeros(1,wtl(end)-1));
                            Gpmsxbt = gpuArray(zeros(1,btl(end)-1));  GpmsxWt = gpuArray(zeros(1,wtl(end)-1));
                            
                        else
                            disp('training on CPU ... ');
                            Gb = b;  GW = W;
                            Gpdb = zeros(size(b));  GpdW = zeros(size(W));
                            Gpmsgbt = zeros(1,btl(end)-1);  GpmsgWt = zeros(1,wtl(end)-1);
                            Gpmsxbt = zeros(1,btl(end)-1);  GpmsxWt = zeros(1,wtl(end)-1);
                            
                        end
                        
                        trainer
                        
                    end
                end
            end
            
        end
        
    case 'adam'
        
        % Training DNN using ADAM - SGD
        % Ref: ADAM : A Method For Stochastic Optimization - ICLR 2015 - D.P.Kingma and J.L.Ba
        
        disp('training with ADAM optimizer ... ');

        for l2 = l2_vec
            for alpha = alpha_vec
                for beta1 = beta1_vec
                    for beta2 = beta2_vec
                        
                        % Step 4 : Weight initialization
                        wt_init
                        
                        arch_name2 = strcat('_l2',num2str(l2),'alpha',num2str(alpha),'_b1',num2str(beta1),'_b2',num2str(beta2),'_',wtinit_meth);
                        arch_name = strcat(arch_name1,arch_name2,'_',num2str(nwt))
                        
                        if gpu_flag
                            fprintf('training on GPU !!! :) \n');
                            Gb = gpuArray(b);
                            GW = gpuArray(W);
                            Gpmbt = gpuArray(zeros(1,btl(end)-1));
                            GpmWt = gpuArray(zeros(1,wtl(end)-1));
                            Gpvbt = gpuArray(zeros(1,btl(end)-1));
                            GpvWt = gpuArray(zeros(1,wtl(end)-1));
                            
                        else
                            disp('training on CPU ... ');
                            Gb = b;  GW = W;
                            Gpmbt = zeros(1,btl(end)-1);  GpmWt = zeros(1,wtl(end)-1);
                            Gpvbt = zeros(1,btl(end)-1);  GpvWt = zeros(1,wtl(end)-1);
                            
                        end
                        
                        trainer
                        
                    end
                end
            end
        end
        
        
end

