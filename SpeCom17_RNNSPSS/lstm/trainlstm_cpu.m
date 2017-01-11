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
##          Date   :  Aug. 2015                                          ##
##                                                                       ##
###########################################################################
%}

% open text file for writing train/test/val error per update
fid = fopen(strcat(errdir,'/err_',arch_name,'.err'),'w');

% load test and validation data onto GPU
val_batchdata       = (val_batchdata);
val_batchtargets    = (val_batchtargets);
test_batchdata      = (test_batchdata);
test_batchtargets   = (test_batchtargets);

% set params of nonlinearity
a_tanh  = 1.7159;
b_tanh  = 2/3;
bby2a   = (b_tanh/(2*a_tanh));

% early stopping params (Theano DeepLearningTutorials)
patience        = 10000;
patience_inc    = 2;
imp_thresh      = 0.995;
val_freq        = min(train_numbats,patience/2);
best_val_loss   = inf;
best_iter       = 0;
num_up          = 0;

valerr  = 0;
testerr = 0;

for NE = 1:numepochs
    
    % for each epoch
    iter = (NE-1)*train_numbats;
    
    % Weight update step
    twu = tic;
    
    aix = randperm(train_numbats);
    % fp and bp for each batch
    for j = 1:train_numbats
        
        X = (train_batchdata(train_clv(aix(j)):train_clv(aix(j)+1)-1,:));
        Y = (train_batchtargets(train_clv(aix(j)):train_clv(aix(j)+1)-1,:));
        sl = train_clv(aix(j)+1) - train_clv(aix(j));
        
        % forward pass
        fp_regression
        
        % backward pass
        E = -(Y - ym)/sl;
        gU = (E'*hm);
        gbu = sum(E)';
        
        Eb = GU'*E';
        [dhm,dom,dcm,dfm,dim,dzm] = bp_lstm(Eb',GRz,GRi,Gpi,GRf,Gpf,GRo,Gpo,zm,im,fm,cm,om,hcm,nl,sl);
        [gWz,gRz,gbz,gWi,gRi,gpi,gbi,gWf,gRf,gpf,gbf,gWo,gRo,gpo,gbo] = gradients_lstm(X,hm,cm,dom,dfm,dim,dzm,nl,sl);
        
        % clip gradients
        if gc_flag
            clip_Gradients
        end
        
        % Check the numerical and back-prop gradients
        if gradCheck_Flag
            compute_NumericalGrad
            compute_GradDiff
        end

        fprintf('Epoch : %d Update: %d maxGradLen : %f %f %f %f %f %f %f %f %f \n',NE,num_up,max(sqrt(sum(gWz.^2,2))),max(sqrt(sum(gWi.^2,2))),max(sqrt(sum(gWf.^2,2))),max(sqrt(sum(gWo.^2,2))), ...
								max(sqrt(sum(gRz.^2,2))),max(sqrt(sum(gRi.^2,2))),max(sqrt(sum(gRf.^2,2))),max(sqrt(sum(gRo.^2,2))),max(sqrt(sum(gU.^2,2))));
 
        % Update Params using Appropriate SGD Method
        num_up = num_up + 1; % Inspired from "ADAM" pseudo code
        update_params
        
        if mod(num_up,check_valfreq) == 0
            
            tic
            valerr = 0;
            % compute error on validation set
            for li = 1:(val_numbats)
                
                X = (val_batchdata(val_clv(li):val_clv(li+1)-1,:));
                Y = (val_batchtargets(val_clv(li):val_clv(li+1)-1,:));
                sl = val_clv(li+1) - val_clv(li);
                fp_regression
 
                switch cfn
                    case 'nll'
                        me = compute_zerooneloss(ym,Y);
                    case 'ls'
                        me = mean(sum((Y - ym).^2,2)./(sum(Y.^2,2)));
                end
                
                valerr = valerr + me/val_numbats;
            end
            toc
            
            %     Print error (validation) per epoc
            fprintf('Epoch : %d Update : %d  Val Loss : %f \n',NE,num_up,valerr);
            
            if valerr < best_val_loss
                if valerr < (best_val_loss*imp_thresh)
                    patience = max(patience,iter*patience_inc);
                end
                best_val_loss = valerr;
                best_iter = iter;
                
                testerr = 0;
                % compute error on test set
                for li = 1:(test_numbats)
                    
                    X = (test_batchdata(test_clv(li):test_clv(li+1)-1,:));
                    Y = (test_batchtargets(test_clv(li):test_clv(li+1)-1,:));
                    sl = test_clv(li+1) - test_clv(li);
                    
                    fp_regression
                    
                    switch cfn
                        case 'nll'
                            me = compute_zerooneloss(ym,Y);
                        case 'ls'
                            me = mean(sum((Y - ym).^2,2)./(sum(Y.^2,2)));
                    end
                    
                    testerr = testerr + me/test_numbats;
                end
                %toc(ttde)
                
                % Print error (testing) per epoc
                fprintf('\t Epoch : %d Update : %d  Test Loss : %f \n',NE,num_up,testerr);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%% save weight file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % save parameters every epoch
                Wz = GWz; Rz = GRz; bz = Gbz; Wi = GWi; Ri = GRi; pi = Gpi; bi = Gbi; Wf = GWf; Rf = GRf; pf = Gpf; bf =Gbf; Wo = GWo; Ro = GRo; po = Gpo; bo = Gbo;
                U = GU; bu = Gbu;
                save(strcat(wtdir,'W_',arch_name,'.mat'),'Wz','Rz','bz','Wi','Ri','pi','bi','Wf','Rf','pf','bf','Wo','Ro','po','bo','U','bu');
            end
            
            
            % Print error (validation and testing) per epoc
            fprintf(fid,'%d %d %f %f \n',NE,num_up,valerr,testerr);
        end
        
        if isnan(valerr) || isnan(max(sqrt(sum(gWi.^2,2)))) || isnan(max(sqrt(sum(gWo.^2,2))))
            break;
        end
        
    end
    toc(twu)
    
    if isnan(valerr) || isnan(max(sqrt(sum(gWi.^2,2)))) || isnan(max(sqrt(sum(gWo.^2,2))))
        break;
    end
    
end


