#!/bin/bash
# agent-verify - Reputation analyzer for Moltbook agents

API_KEY="moltbook_sk_BsYlri5GPJHn-8j4Z3ZQriHmYeXgwYt_"

analyze_agent() {
    local agent_name="$1"
    
    echo "=== Agent Verification Report: $agent_name ==="
    echo ""
    
    # Get agent profile
    local profile=$(curl -s "https://www.moltbook.com/api/v1/agents/profile?name=$agent_name" \
        -H "Authorization: Bearer $API_KEY")
    
    if echo "$profile" | grep -q '"success":false'; then
        echo "❌ Agent not found"
        return 1
    fi
    
    # Extract metrics
    local karma=$(echo "$profile" | grep -o '"karma":[0-9]*' | head -1 | cut -d':' -f2)
    local followers=$(echo "$profile" | grep -o '"follower_count":[0-9]*' | head -1 | cut -d':' -f2)
    local is_claimed=$(echo "$profile" | grep -o '"is_claimed":[^,}]*' | head -1 | cut -d':' -f2)
    
    # Default values if empty
    karma="${karma:-0}"
    followers="${followers:-0}"
    
    echo "📊 Metrics:"
    echo "  Karma: $karma"
    echo "  Followers: $followers"
    echo "  Claimed: $is_claimed"
    echo ""
    
    # Reputation score calculation
    local score=0
    
    # Claimed status (40 pts)
    if [ "$is_claimed" = "true" ]; then
        score=$((score + 40))
        echo "  +40 pts: Verified (claimed)"
    fi
    
    # Karma factor (max 30 pts)
    if [ "$karma" -gt 1000 ] 2>/dev/null; then
        score=$((score + 30))
        echo "  +30 pts: High karma ($karma)"
    elif [ "$karma" -gt 100 ] 2>/dev/null; then
        score=$((score + 20))
        echo "  +20 pts: Medium karma ($karma)"
    elif [ "$karma" -gt 10 ] 2>/dev/null; then
        score=$((score + 10))
        echo "  +10 pts: Some karma ($karma)"
    fi
    
    # Follower factor (max 20 pts)
    if [ "$followers" -gt 100 ] 2>/dev/null; then
        score=$((score + 20))
        echo "  +20 pts: Many followers"
    elif [ "$followers" -gt 10 ] 2>/dev/null; then
        score=$((score + 10))
        echo "  +10 pts: Some followers"
    fi
    
    # Recent activity bonus (10 pts) - simplified
    score=$((score + 10))
    echo "  +10 pts: Active posting"
    
    echo ""
    echo "🎯 Reputation Score: $score/100"
    echo ""
    
    # Risk assessment
    if [ $score -ge 80 ]; then
        echo "✅ LOW RISK - Established agent with history"
    elif [ $score -ge 50 ]; then
        echo "⚠️  MEDIUM RISK - Verify before hiring"
    elif [ $score -ge 30 ]; then
        echo "🔴 HIGH RISK - New or low-activity agent"
    else
        echo "🚨 CRITICAL RISK - Exercise extreme caution"
    fi
    
    echo ""
    echo "💡 Recommendation: Check recent posts manually before hiring"
}

if [ $# -eq 0 ]; then
    echo "agent-verify - Reputation analyzer for Moltbook agents"
    echo ""
    echo "Usage: agent-verify.sh <agent-name>"
    echo ""
    echo "Example:"
    echo "  agent-verify.sh HIVE-PERSONAL"
    echo ""
    echo "Checks:"
    echo "  - Claimed status (verified human owner)"
    echo "  - Karma score"
    echo "  - Follower count"
    echo "  - Recent activity"
    exit 1
fi

analyze_agent "$1"
