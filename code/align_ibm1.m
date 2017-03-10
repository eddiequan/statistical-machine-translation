function AM = align_ibm1(trainDir, numSentences, maxIter, fn_AM)
%
%  align_ibm1
% 
%  This function implements the training of the IBM-1 word alignment algorithm. 
%  We assume that we are implementing P(foreign|english)
%
%  INPUTS:
%
%       dataDir      : (directory name) The top-level directory containing 
%                                       data from which to train or decode
%                                       e.g., '/u/cs401/A2_SMT/data/Toy/'
%       numSentences : (integer) The maximum number of training sentences to
%                                consider. 
%       maxIter      : (integer) The maximum number of iterations of the EM 
%                                algorithm.
%       fn_AM        : (filename) the location to save the alignment model,
%                                 once trained.
%
%  OUTPUT:
%       AM           : (variable) a specialized alignment model structure
%
%
%  The file fn_AM must contain the data structure called 'AM', which is a 
%  structure of structures where AM.(english_word).(foreign_word) is the
%  computed expectation that foreign_word is produced by english_word
%
%       e.g., LM.house.maison = 0.5       % TODO
% 
% Template (c) 2011 Jackie C.K. Cheung and Frank Rudzicz
  
  global CSC401_A2_DEFNS
  
  AM = struct();
  
  % Read in the training data
  [eng, fre] = read_hansard(trainDir, numSentences);
  
  % Initialize AM uniformly
  AM = initialize(eng, fre);
  
  % Iterate between E and M steps
  for iter=1:maxIter,
      AM = em_step(AM, eng, fre);
  end
  
  % Save the alignment model
  save( fn_AM, 'AM', '-mat');
  
end

% --------------------------------------------------------------------------------
%
%  Support functions
%
% --------------------------------------------------------------------------------

function [eng, fre] = read_hansard(mydir, numSentences)
%
% Read 'numSentences' parallel sentences from texts in the 'dir' directory.
%
% Important: Be sure to preprocess those texts!
%
% Remember that the i^th line in fubar.e corresponds to the i^th line in fubar.f
% You can decide what form variables 'eng' and 'fre' take, although it may be easiest
% if both 'eng' and 'fre' are cell-arrays of cell-arrays, where the i^th element of
% 'eng', for example, is a cell-array of words that you can produce with
%
%         eng{i} = strsplit(' ', preprocess(english_sentence, 'e'));
%
eng = {};
fre = {};

% TODO: your code goes here.
ENG_DD = dir( [ mydir, filesep, '*', 'e'] );
FRE_DD = dir( [ mydir, filesep, '*', 'f'] );

lines_written = 1;

for iFile=1:length(ENG_DD)
    english_lines = textread([mydir, filesep, ENG_DD(iFile).name], '%s','delimiter','\n');
    french_lines = textread([mydir, filesep, FRE_DD(iFile).name], '%s','delimiter','\n');

    for l=1:length(english_lines)
        
        eng{lines_written} = strsplit(' ', preprocess(english_lines{l}, 'e'));
        fre{lines_written} = strsplit(' ', preprocess(french_lines{l}, 'f'));

        lines_written = lines_written + 1;

        if (lines_written > numSentences)
          return;
        end
    end
end
end


function AM = initialize(eng, fre)
%
% Initialize alignment model uniformly.
% Only set non-zero probabilities where word pairs appear in corresponding sentences.
%
    AM = {}; % AM.(english_word).(foreign_word)
    AM.SENTSTART.SENTSTART = 1;
    AM.SENTEND.SENTEND = 1;

    % TODO: your code goes here
    % initialize AM english words
    for sentence=1:length(eng)
        for eng_word_index=2:length(eng{sentence})-1
            for fre_word_index=2:length(fre{sentence})-1
                eng_word = eng{sentence}{eng_word_index};
                fre_word = fre{sentence}{fre_word_index};
                
                if ~isfield(AM, eng_word)
                    AM.(eng_word) = struct();
                end
                
                if ~isfield(AM.(eng_word), fre_word)
                    AM.(eng_word).(fre_word) = 0;
                end
                
            end
        end
    end
    
    eng_words = fieldnames(AM);
    
    for word=1:length(eng_words)
        possible_pairs = fieldnames(AM.(eng_words{word}));
        num_french_pairs = length(possible_pairs);
        
        for french_word_index=1:num_french_pairs
            eng_word = eng_words{word};
            fre_word = possible_pairs{french_word_index};
            AM.(eng_word).(fre_word) = rdivide(1, num_french_pairs);
        end
    end

end

function t = em_step(t, eng, fre)
% 
% One step in the EM algorithm.
%
  
  % TODO: your code goes here
  
  eng_words = fieldnames(t);
  french_words = {};
  for word=1:length(eng_words)
      french_words = [french_words; fieldnames(t.(eng_words{word}))];
  end
  
  % initialize tcount
  tcount = struct();
  tcount.SENTSTART.SENTSTART = 0;
  tcount.SENTEND.SENTEND = 0;
  
  % initialize total
  total = struct();
  total.SENTSTART = 0;
  total.SENTEND = 0;
  
  for sentence_index=1:length(eng)
      english_sentence = eng{sentence_index}(2:length(eng{sentence_index})-1);
      french_sentence = fre{sentence_index}(2:length(fre{sentence_index})-1);
      
      % handle unique words
      
      for i=1:length(french_sentence)
          
          % Step 1
          sum_alignment_probability = 0;
          for j=1:length(english_sentence)
              % FcountF??
              sum_alignment_probability = sum_alignment_probability + t.(english_sentence{j}).(french_sentence{i});
          end
          
          for j=1:length(english_sentence)
              alignment_probability = t.(english_sentence{j}).(french_sentence{i});
              partial_tcount = rdivide(alignment_probability, sum_alignment_probability);
              
              % add struct fields if they do not already exist
              if ~isfield(tcount, french_sentence{i})
                  tcount.(french_sentence{i}) = struct(); 
              end
              if ~isfield(tcount.(french_sentence{i}), english_sentence{j})
                  tcount.(french_sentence{i}).(english_sentence{j}) = 0;
              end
              
              tcount.(french_sentence{i}).(english_sentence{j}) = tcount.(french_sentence{i}).(english_sentence{j}) + partial_tcount;
              
              % initialize total field if non-existent
              if ~isfield(total, english_sentence{j})
                  total.(english_sentence{j}) = 0;
              end
              
              total.(english_sentence{j}) = total.(english_sentence{j}) + partial_tcount;
              
          end
          
      end
      
      
  end
  
  for i=1:length(eng_words)
      eng_word = eng_words{i};
      french_pairs = fieldnames(t.(eng_word));
      
      for j=1:length(french_pairs)
          fre_word = french_pairs{j};
          
          current_alignment_probability = tcount.(fre_word).(eng_word);
          disp(total);
          current_total = total.(eng_word);
          disp(current_total);
          updated_alignment_probability = rdivide(current_alignment_probability, current_total);
          t.(eng_word).(fre_word) = updated_alignment_probability;
      end
  end
  
end


