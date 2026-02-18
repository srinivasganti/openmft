---
name: document
description: Create timestamped session documentation in the .session_details directory
user-invocable: true
---

# Create Session Documentation

Create documentation for changes made during a session in a timestamped file within the `.session_details/` directory.

## Instructions

1. **Generate Timestamped File**: Create file with format `YYYYMMDD_HHMMSS_<short_description>.md`
   - Example: `.session_details/20260211_164209_initial_build.md`
   - Use current date and time when skill is invoked
   - Use a short snake_case description of the work done

2. **Document Template**:
   ```markdown
   # Session: YYYY-MM-DD HH:MM - <Title>

   ## Summary
   <Brief 2-3 sentence summary of what was done>

   ## Changes Made

   ### Modified Files
   | File | Description |
   |------|-------------|
   | path/to/file.ex | What was changed |

   ### New Files
   | File | Purpose |
   |------|---------|
   | path/to/new_file.ex | Why it was created |

   ## Technical Details
   <Detailed explanation of implementation approach, patterns used, etc.>

   ## Fixes Applied
   <List any bugs found and fixed during this session>

   ## Status
   <Current state: what works, what's pending>
   ```

3. **Gather Information**:
   - Run `git diff --stat` to see changed files since last commit
   - Run `git log --oneline -5` for recent commit context
   - Run `git status` for uncommitted changes
   - Review any screenshots in `.screenshots/` added during session

4. **Best Practices**:
   - Document the "why" not just the "what"
   - Include specific error messages and how they were resolved
   - Note any configuration changes needed
   - Reference specific file paths and line numbers
   - Keep documentation concise but complete
   - Each session builds on previous session documentation
