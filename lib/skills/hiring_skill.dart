/// Hiring & Recruitment Skill definitions with Function Calling tools
library;

/// Hiring & Recruitment Skill with Function Calling support
class HiringSkill {
  // ==================== Tool Definitions ====================

  /// Tool: Generate Job Description
  static Map<String, dynamic> get jobDescriptionTool => {
        'name': 'generate_job_description',
        'description': 'Generate a comprehensive job description with role details, responsibilities, requirements, and interview process',
        'parameters': {
          'type': 'object',
          'properties': {
            'role_title': {
              'type': 'string',
              'description': 'Job title (e.g., "Senior Software Engineer", "Product Manager")',
            },
            'team': {
              'type': 'string',
              'description': 'Team or department name',
            },
            'role_level': {
              'type': 'string',
              'description': 'Experience level',
              'enum': ['junior', 'mid', 'senior', 'staff', 'principal', 'manager', 'director'],
            },
            'about_role': {
              'type': 'string',
              'description': '2-3 sentences about role impact and scope',
            },
            'responsibilities': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of key responsibilities (4-6 items)',
            },
            'must_have': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Required qualifications and skills',
            },
            'nice_to_have': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Bonus qualifications',
            },
            'benefits': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Key benefits and perks',
            },
            'compensation_range': {
              'type': 'string',
              'description': 'Salary range (optional)',
            },
          },
          'required': ['role_title', 'team', 'role_level', 'about_role'],
        },
      };

  /// Tool: Create Interview Scorecard
  static Map<String, dynamic> get scorecardTool => {
        'name': 'create_interview_scorecard',
        'description': 'Create a structured interview scorecard for evaluating candidates',
        'parameters': {
          'type': 'object',
          'properties': {
            'candidate': {
              'type': 'string',
              'description': 'Candidate name (placeholder: "Candidate Name")',
            },
            'role': {
              'type': 'string',
              'description': 'Position being interviewed for',
            },
            'interviewer': {
              'type': 'string',
              'description': 'Interviewer name (placeholder: "Interviewer Name")',
            },
            'interview_type': {
              'type': 'string',
              'description': 'Type of interview',
              'enum': ['technical', 'design', 'behavioral', 'finalRound', 'recruiter'],
            },
            'competencies': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'competency': {
                    'type': 'string',
                    'enum': [
                      'technicalSkills',
                      'problemSolving',
                      'communication',
                      'collaboration',
                      'growthMindset',
                      'leadership',
                    ],
                  },
                  'weight': {'type': 'number'},
                },
              },
            },
          },
          'required': ['role', 'interview_type'],
        },
      };

  /// Tool: Generate STAR Interview Questions
  static Map<String, dynamic> get starQuestionsTool => {
        'name': 'generate_star_questions',
        'description': 'Generate behavioral interview questions using STAR framework',
        'parameters': {
          'type': 'object',
          'properties': {
            'role': {
              'type': 'string',
              'description': 'Position title',
            },
            'competency_focus': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Competencies to focus on (e.g., "problem_solving", "leadership")',
            },
            'question_count': {
              'type': 'number',
              'description': 'Number of questions to generate (default: 5)',
            },
          },
          'required': ['role'],
        },
      };

  /// Tool: Generate Hiring Metrics
  static Map<String, dynamic> get metricsTool => {
        'name': 'generate_hiring_metrics',
        'description': 'Generate hiring pipeline metrics and targets for tracking recruitment performance',
        'parameters': {
          'type': 'object',
          'properties': {
            'role': {
              'type': 'string',
              'description': 'Position title',
            },
            'team_size': {
              'type': 'number',
              'description': 'Current team size',
            },
            'urgency': {
              'type': 'string',
              'description': 'Hiring urgency level',
              'enum': ['low', 'medium', 'high', 'critical'],
            },
          },
          'required': ['role'],
        },
      };

  /// Tool: Analyze Candidate Fit
  static Map<String, dynamic> get candidateAnalysisTool => {
        'name': 'analyze_candidate_fit',
        'description': 'Analyze candidate fit based on resume, experience, and interview feedback',
        'parameters': {
          'type': 'object',
          'properties': {
            'candidate_name': {
              'type': 'string',
              'description': 'Candidate name',
            },
            'role': {
              'type': 'string',
              'description': 'Position applied for',
            },
            'experience_summary': {
              'type': 'string',
              'description': 'Brief summary of candidate experience',
            },
            'key_strengths': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Identified strengths',
            },
            'concerns': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Areas of concern',
            },
            'interview_feedback': {
              'type': 'string',
              'description': 'Summary of interview feedback',
            },
          },
          'required': ['candidate_name', 'role', 'experience_summary'],
        },
      };

  // ==================== System Prompts ====================

  /// System prompt for job description generation
  static String get jobDescriptionPrompt => '''
You are an expert HR assistant specializing in creating job descriptions for the Indonesian market.

Your task is to generate professional, attractive job descriptions that:
- Are written in clear, professional Indonesian
- Include realistic expectations for the position level
- Have practical requirements suitable for Indonesian tech market
- Highlight growth opportunities and team culture
- Follow the structured format provided

Always respond with a function call to generate_job_description with all required fields.
''';

  /// System prompt for scorecard creation
  static String get scorecardPrompt => '''
You are an expert interviewer creating structured evaluation frameworks.

Your task is to create interview scorecards that:
- Use objective, measurable criteria
- Weight competencies appropriately for the role
- Include clear scoring guides (1-5 scale)
- Provide examples of strong signals and red flags
- Help reduce bias through structured evaluation

Always respond with a function call to create_interview_scorecard.
''';

  /// System prompt for STAR questions
  static String get starQuestionsPrompt => '''
You are an expert interviewer specializing in behavioral interviewing using the STAR framework.

STAR Framework:
- Situation: Context and background
- Task: Specific responsibility
- Action: Steps taken (focus on "I" not "we")
- Result: Outcome and learning

Generate questions that:
- Are open-ended and behavior-based
- Reveal specific examples from past experience
- Assess key competencies for the role
- Help predict future performance

Always respond with a function call to generate_star_questions.
''';

  /// System prompt for hiring metrics
  static String get metricsPrompt => '''
You are an expert HR analyst specializing in recruitment metrics and funnel optimization.

Your task is to create hiring metrics that:
- Track key conversion rates through the pipeline
- Monitor time-to-hire and quality metrics
- Set realistic targets based on role urgency
- Identify red flags that require attention
- Help improve hiring process efficiency

Always respond with a function call to generate_hiring_metrics.
''';

  /// System prompt for candidate analysis
  static String get candidateAnalysisPrompt => '''
You are an expert hiring manager evaluating candidate fit for engineering roles.

Your analysis should:
- Consider both technical skills and cultural fit
- Weigh strengths against concerns objectively
- Consider growth potential and learning ability
- Provide clear hiring recommendation with rationale
- Suggest next steps in the process

Always respond with a function call to analyze_candidate_fit.
''';

  // ==================== Helper Methods ====================

  /// Get all available tools
  static List<Map<String, dynamic>> get allTools => [
        jobDescriptionTool,
        scorecardTool,
        starQuestionsTool,
        metricsTool,
        candidateAnalysisTool,
      ];

  /// Get tool by name
  static Map<String, dynamic>? getToolByName(String name) {
    for (final tool in allTools) {
      if (tool['name'] == name) return tool;
    }
    return null;
  }

  /// Get system prompt for skill
  static String getSystemPrompt(String skill) {
    switch (skill) {
      case 'generate_job_description':
        return jobDescriptionPrompt;
      case 'create_interview_scorecard':
        return scorecardPrompt;
      case 'generate_star_questions':
        return starQuestionsPrompt;
      case 'generate_hiring_metrics':
        return metricsPrompt;
      case 'analyze_candidate_fit':
        return candidateAnalysisPrompt;
      default:
        return '''You are an expert HR assistant helping with hiring and recruitment tasks.
Use the appropriate function calls to provide structured, professional outputs.''';
    }
  }

}
