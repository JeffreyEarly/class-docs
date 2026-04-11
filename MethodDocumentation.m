classdef MethodDocumentation < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        name string
        definingClassName
        declaringClassName = string.empty(0,0)
        parameters
        returns
        detailedDescription =[]
        shortDescription = []
        declaration = []
        topic = []
        subtopic = []
        subsubtopic = []
        nav_order = Inf
        functionType
        access = 'public'
        isHidden = 0
        isDeveloper = false

        pathOfOutputFile = [] % path on the local hard drive
        pathOfFileOnWebsite = []

        dimensions
        units
        isComplex
    end

    methods
        function self = MethodDocumentation(name)
            self.name = name;
        end

        function addDeclaringClass(self,name)
            arguments
                self MethodDocumentation
                name string
            end
            self.declaringClassName(end+1) = name;
        end

        function flag = isDeclaredInClass(self,name)
            arguments
                self MethodDocumentation
                name string
            end
            flag = ismember(name,self.declaringClassName);
        end

        function addMetadataFromMethodMetadata(self,mp)
            arguments
                self MethodDocumentation
                mp meta.method
            end
            self.access = MethodDocumentation.normalizedAccessText(mp.Access);
            self.isHidden = mp.Hidden;
            self.definingClassName = mp.DefiningClass.Name;
            self.shortDescription = mp.Description;
            if mp.Static == 1
                self.functionType = FunctionType.staticMethod;
            elseif mp.Abstract == 1
                self.functionType = FunctionType.abstractMethod;
            else
                self.functionType = FunctionType.instanceMethod;
            end
        end

        function addMetadataFromPropertyMetadata(self,mp)
            arguments
                self MethodDocumentation
                mp meta.property
            end
            self.access = MethodDocumentation.normalizedAccessText(mp.GetAccess);
            self.isHidden = mp.Hidden;
            self.definingClassName = mp.DefiningClass.Name;
            self.shortDescription = mp.Description;
            self.functionType = FunctionType.instanceProperty;
        end

        function self = addMetadataFromDetailedDescription(self,detailedDescription)
            if isempty(detailedDescription)
                return;
            end

            % Check out https://regexr.com for testing these regex.
            topicExpression = '- topic:([ \t]*)(?<topic>[^\r\n]+)(?:$|\n)';
            subtopicExpression = '- topic:([ \t]*)(?<topic>[^—\r\n]+)—([ \t]*)(?<subtopic>[^\r\n]+)(?:$|\n)';
            subsubtopicExpression = '- topic:([ \t]*)(?<topic>[^—\r\n]+)—([ \t]*)(?<subtopic>[^\r\n]+)—([ \t]*)(?<subsubtopic>[^\r\n]+)(?:$|\n)';
            declarationExpression = '- declaration:(?<declaration>[^\r\n]+)(?:$|\n)';
            parameterExpression = '- parameter (?<name>[^:]+):(?<description>[^\r\n]+)(?:$|\n)';
            returnsExpression = '- returns (?<name>[^:]+):(?<description>[^\r\n]+)(?:$|\n)';
            navOrderExpression = '- nav_order:([ \t]*)(?<nav_order>[^\r\n]+)(?:$|\n)';
            developerExpression = '- developer:([ \t]*)(?<isDeveloper>[^\r\n]+)(?:$|\n)';
            leadingWhitespaceExpression = '^[ \t]+';

            % Capture the subsubtopic annotation, then remove it
            matchStr = regexpi(detailedDescription,subsubtopicExpression,'names');
            detailedDescription = regexprep(detailedDescription,subsubtopicExpression,'','ignorecase');
            if ~isempty(matchStr)
                self.subsubtopic = strtrim(matchStr.subsubtopic);
                self.subtopic = strtrim(matchStr.subtopic);
                self.topic = strtrim(matchStr.topic);
            end

            % Capture the subtopic annotation, then remove it
            matchStr = regexpi(detailedDescription,subtopicExpression,'names');
            detailedDescription = regexprep(detailedDescription,subtopicExpression,'','ignorecase');
            if ~isempty(matchStr)
                self.subtopic = strtrim(matchStr.subtopic);
                self.topic = strtrim(matchStr.topic);
            end

            % Capture the topic annotation, then remove it
            matchStr = regexpi(detailedDescription,topicExpression,'names');
            detailedDescription = regexprep(detailedDescription,topicExpression,'','ignorecase');
            if ~isempty(matchStr)
                self.topic = strtrim(matchStr.topic);
            end

            % Capture all parameters, then remove the annotations
            self.parameters = regexpi(detailedDescription,parameterExpression,'names');
            detailedDescription = regexprep(detailedDescription,parameterExpression,'','ignorecase');

            % Capture all returns, then remove the annotations
            self.returns = regexpi(detailedDescription,returnsExpression,'names');
            detailedDescription = regexprep(detailedDescription,returnsExpression,'','ignorecase');


            % Capture any declarations made, then remove the annotation
            matchStr = regexpi(detailedDescription,declarationExpression,'names');
            detailedDescription = regexprep(detailedDescription,declarationExpression,'','ignorecase');
            if ~isempty(matchStr)
                self.declaration = matchStr.declaration;
            end

            matchStr = regexpi(detailedDescription,navOrderExpression,'names');
            detailedDescription = regexprep(detailedDescription,navOrderExpression,'','ignorecase');
            if ~isempty(matchStr)
                self.nav_order = str2double(matchStr.nav_order);
            end

            matchStr = regexpi(detailedDescription,developerExpression,'names');
            detailedDescription = regexprep(detailedDescription,developerExpression,'','ignorecase');
            if ~isempty(matchStr)
                value = lower(strtrim(string(matchStr(1).isDeveloper)));
                self.isDeveloper = ismember(value, ["true","1","yes"]);
            end


            self.detailedDescription = regexprep(detailedDescription,leadingWhitespaceExpression,'');
        end

        function writeToFile(self,parentName,pageNumber)
            if isempty(self.pathOfOutputFile)
                error('Path not set!');
            end
            fileID = fopen(self.pathOfOutputFile,'w');

            fprintf(fileID,'---\nlayout: default\ntitle: %s\nparent: %s\ngrand_parent: Classes\nnav_order: %d\nmathjax: true\n---\n\n',self.name,parentName,pageNumber);

            fprintf(fileID,'#  %s\n',self.name);
            fprintf(fileID,'\n%s\n',self.shortDescription);
            if self.isDeveloper
                fprintf(fileID,'\n> Developer documentation: this item describes internal implementation details.\n');
            end

            fprintf(fileID,'\n\n---\n\n');

            if (self.functionType == FunctionType.transformProperty || self.functionType == FunctionType.stateVariable)
                fprintf(fileID,'## Description\n');
                if self.isComplex == 1
                    str = 'Complex valued ';
                else
                    str = 'Real valued ';
                end

                if self.functionType == FunctionType.transformProperty
                    str = strcat(str,' property ');
                else
                    str = strcat(str,' state variable ');
                end

                if isempty(self.dimensions)
                    str = strcat(str,' with no dimensions and ');
                elseif length(self.dimensions) == 1
                    str = strcat(str,' with dimension $$',self.dimensions{1},'$$ and ');
                else
                    str = strcat(str,' with dimensions $$(');
                    for iDim=1:(length(self.dimensions)-1)
                        str = strcat(str,self.dimensions{iDim},',');
                    end
                    str = strcat(str,self.dimensions{end},')$$ and');
                end

                if isempty(self.units)
                    str = strcat(str,' no units.\n\n');
                else
                    str = strcat(str,' units of $$',self.units,'$$.\n\n');
                end
                fprintf(fileID,str);
            end

            % ## Description
            % (Real/Complex) valued (transform property/state variable) with (no
            % dimensions/dimension {x,y,z}) and (no units/units of xxx).



            if ~isempty(self.declaration)
                fprintf(fileID,'## Declaration\n');
                fprintf(fileID,'```matlab\n%s\n```\n',self.declaration);
            end

            if ~isempty(self.parameters)
                fprintf(fileID,'## Parameters\n');
                for iParameter=1:length(self.parameters)
                    fprintf(fileID,'+ `%s` %s\n',self.parameters(iParameter).name,self.parameters(iParameter).description);
                end
                fprintf(fileID,'\n');
            end

            if ~isempty(self.returns)
                fprintf(fileID,'## Returns\n');
                for iReturn=1:length(self.returns)
                    fprintf(fileID,'+ `%s` %s\n',self.returns(iReturn).name,self.returns(iReturn).description);
                end
                fprintf(fileID,'\n');
            end

            if ~isempty(self.detailedDescription)
                fprintf(fileID,'## Discussion\n%s\n',self.detailedDescription);
            end

            fclose(fileID);
        end
    end

    methods (Static, Access = private)
        % Normalize reflected access metadata to simple text labels for
        % documentation filtering. For example, MATLAB reports
        % `methods (Access = {?FriendA, ?FriendB})` as a cell containing
        % `meta.class` entries, and we treat that friend-only case as
        % `"private"` because `class-docs` only needs to distinguish
        % public API from non-public members when deciding what to publish.
        function accessText = normalizedAccessText(access)
            if isstring(access) && isscalar(access)
                accessText = access;
                return
            end

            if ischar(access)
                accessText = string(access);
                return
            end

            if iscell(access)
                accessEntries = strings(numel(access), 1);
                for iEntry = 1:numel(access)
                    accessEntries(iEntry) = MethodDocumentation.normalizedAccessText(access{iEntry});
                end

                if any(strcmpi(accessEntries, "public"))
                    accessText = "public";
                else
                    accessText = "private";
                end
                return
            end

            if isa(access, "meta.class")
                accessText = string(access.Name);
                return
            end

            accessText = string(class(access));
        end
    end
end
