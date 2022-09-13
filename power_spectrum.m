function [spect,varargout]=power_spectrum(sig,win,fs,bounds,res,corr,quitmains)
%POWER_SPECTRUM   Positive-frequencies-only power spectrum.
%   S=POWER_SPECTRUM(SIGNAL)
%   S=POWER_SPECTRUM(SIGNAL,WIN)
%   S=POWER_SPECTRUM(SIGNAL,WIN,FS,BOUNDS)
%   S=POWER_SPECTRUM(SIGNAL,WIN,FS,BOUNDS,RESOLUTION)
%   S=POWER_SPECTRUM(SIGNAL,WIN,FS,BOUNDS,RESOLUTION,CORRECTION)
%   [...,BINFREQS]=POWER_SPECTRUM(SIGNAL,WIN,FS,...)
try
[M,N]=size(sig);
if nargin>1 && ~isempty(win)
   if islogical(win)
      if win
         sig(:)=sig.*repmat(reshape(hanning(N),1,N),M,1);
      end%if
   elseif isa(win,'function_handle')
      sig(:)=sig.*repmat(reshape(win(N),1,N),M,1);
   elseif isnumeric(win) && numel(win)==N
      sig(:)=sig.*repmat(reshape(win,1,N),M,1);
   end%if
end%if
spect=fft(sig,[],2);
Q=floor(N/2);
spect(:,Q+2:end)=[];
P=fs/(2*Q);
tobin=@(a)round(a/P)+1;
corr_p=nargin>5 && ~isempty(corr);
quitmains=nargin>6 && quitmains;
if quitmains
mainswidth=1;
mains1=tobin(50-mainswidth:50:fs/2-mainswidth);
mains2=50+mainswidth:50:fs/2;
if numel(mains2)<numel(mains1)
   mains2(1,end+1)=fs/2;
end%if
mains2=tobin(mains2);
mains=zeros(1,(mains2(1)-mains1(1)+1)*(numel(mains1)-1)+mains2(end)-mains1(end)+1);
k=0;
for j=1:numel(mains1)
   mains(k+1:k+mains2(j)-mains1(j)+1)=mains1(j):mains2(j);
   k=k+mains2(j)-mains1(j)+1;
end%for j
clear mains1 mains2;
end%if
if corr_p
   spect=real(spect.*conj(spect));
   corr=tobin(corr);
   x=setdiff(corr(1):corr(2),mains)';
   y=spect(:,x)';
   [a,b]=regr(log(x),log(y),'log'); clear x y;
if 0
y=spect';
x=0:fs/N:(size(y,1)-1)*(fs/N);
figure;
plot(x,log(y),'b-'); hold on;
plot(x,a*log(tobin(x))+b,'r-');
keyboard
close;
end%if
   spect(:)=spect./exp(a*log(1:size(spect,2))+repmat(b,1,size(spect,2)));
end%if
if quitmains
   spect(:,mains)=NaN;
end%if
spect(:,1)=spect(:,1)/2;
if mod(N,2)==0
   spect(:,Q+1)=spect(:,Q+1)/2;
end%if
if nargin>3 && ~isempty(bounds)
   if nargin>4 && ~isempty(res)
      bounds(:)=bounds+[-1,1]*res/2;
   end%if
   binfreqs=bounds;
   bounds=tobin(bounds);
   spect(:,[1:bounds(1)-1,bounds(2)+1:end])=[];
else
   binfreqs=[0,fs/2];
end%if
if ~corr_p
spect=real(spect.*conj(spect))/(N/2);
end%if
actual_res=fs/N;
if nargin>4 && ~isempty(res)
if res<actual_res
   error('cannot increase spectral resolution.');
else
   groupby_=res/actual_res;
   groupby=round(groupby_);
   if groupby~=groupby_
      warning('using %f resolution instead',actual_res*groupby);
   end%if
   if groupby>1
   nbins=floor(size(spect,2)/groupby);
   for b=1:nbins
      tmp=spect(:,(b-1)*groupby+1:b*groupby);
      ok=~isnan(tmp);
      if ~all(ok)
      if any(ok)
      tmp(~ok)=0;
      mn=sum(tmp,2)./sum(ok,2);
      tmp(~ok)=mn;
      else
      tmp(:)=nan;
      end%if
      end%if
      spect(:,b)=sum(tmp,2);
   end%for b
   spect(:,nbins+1:end)=[];
   end%if
   actual_res=res;
   binfreqs=binfreqs+[1,-1]*res/2;
end%if
end%if
if nargout>1
binfreqs=binfreqs(1):actual_res:binfreqs(2);
varargout{1}=binfreqs;
end%if
if size(sig,1)==1
   spect=spect';
end%if
catch
err=lasterror;
disp(err.message)
disp(err.stack(1))
keyboard
rethrow(err);
end%try
end%function
