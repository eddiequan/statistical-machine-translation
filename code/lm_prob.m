function logProb = lm_prob(sentence, LM, type, delta, vocabSize)
%
%  lm_prob
% 
%  This function computes the LOG probability of a sentence, given a 
%  language model and whether or not to apply add-delta smoothing
%
%  INPUTS:
%
%       sentence  : (string) The sentence whose probability we wish
%                            to compute
%       LM        : (variable) the LM structure (not the filename)
%       type      : (string) either '' (default) or 'smooth' for add-delta smoothing
%       delta     : (float) smoothing parameter where 0<delta<=1 
%       vocabSize : (integer) the number of words in the vocabulary
%
% Template (c) 2011 Frank Rudzicz

  logProb = -Inf;

  % some rudimentary parameter checking
  if (nargin < 2)
    disp( 'lm_prob takes at least 2 parameters');
    return;
  elseif nargin == 2
    type = '';
    delta = 0;
    vocabSize = length(fieldnames(LM.uni));
  end
  if (isempty(type))
    delta = 0;
    vocabSize = length(fieldnames(LM.uni));
  elseif strcmp(type, 'smooth')
    if (nargin < 5)  
      disp( 'lm_prob: if you specify smoothing, you need all 5 parameters');
      return;
    end
    if (delta <= 0) or (delta > 1.0)
      disp( 'lm_prob: you must specify 0 < delta <= 1.0');
      return;
    end
  else
    disp( 'type must be either '''' or ''smooth''' );
    return;
  end

  words = strsplit(' ', sentence);

  % TODO: the student implements the following
  logProb = 0;
  
  for word=2:length(words)
      first_word = words{word-1};
      second_word = words{word};
      
      if isfield(LM.bi, first_word)
          num_first_word = LM.uni.(first_word);
      else
          num_first_word = 0;
      end
      
      if isfield(LM.bi, first_word) && isfield(LM.bi.(first_word), second_word)
          num_second_word_given_first = LM.bi.(first_word).(second_word);
      else
          num_second_word_given_first = 0;
      end
      
      % TODO: Implement lines 70-82
      second_word_delta_occurrences = (num_second_word_given_first + delta);
      first_word_delta_occurrences = (num_first_word + delta*vocabSize);
      
      if (second_word_delta_occurrences == 0 && first_word_delta_occurrences == 0)
          logProb = -Inf;
          break
      else
          bigram_prob = rdivide(second_word_delta_occurrences, first_word_delta_occurrences);
          disp(log2(bigram_prob));
          logProb = logProb + log2(bigram_prob);
      end
  end
  
  % TODO: once upon a time there was a curmudgeonly orangutan named Jub-Jub.
return