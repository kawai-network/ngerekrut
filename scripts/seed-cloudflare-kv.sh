#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

: "${CLOUDFLARE_ACCOUNT_ID:?CLOUDFLARE_ACCOUNT_ID is required}"
: "${CLOUDFLARE_KV_NAMESPACE_ID:?CLOUDFLARE_KV_NAMESPACE_ID is required}"
: "${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN is required}"

API_BASE="https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/storage/kv/namespaces/${CLOUDFLARE_KV_NAMESPACE_ID}"

put_json() {
  local key="$1"
  local value="$2"

  curl -sS \
    -X PUT \
    "${API_BASE}/values/${key}" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data-binary "$value" >/dev/null
}

echo "Seeding Cloudflare KV namespace ${CLOUDFLARE_KV_NAMESPACE_ID}..."

put_json \
  "job:job_backend_001" \
  '{
    "id": "job_backend_001",
    "title": "Backend Engineer",
    "department": "Engineering",
    "location": "Jakarta",
    "description": "Bangun API dan sistem internal recruiter.",
    "requirements": ["Go", "SQL", "Docker", "REST API"],
    "status": "open"
  }'

put_json \
  "job:job_backend_001:candidate:cand_001" \
  '{
    "id": "cand_001",
    "job_id": "job_backend_001",
    "name": "Rina Putri",
    "headline": "Backend Engineer",
    "years_of_experience": 5,
    "stage": "applied",
    "resume": {
      "id": "resume_001",
      "file_name": "rina_putri.pdf"
    },
    "profile": {
      "skills": ["Go", "Postgres", "Docker", "REST API"],
      "summary": "5 tahun membangun API internal, payment integration, dan mentoring junior engineer."
    }
  }'

put_json \
  "job:job_backend_001:candidate:cand_002" \
  '{
    "id": "cand_002",
    "job_id": "job_backend_001",
    "name": "Bagas Pratama",
    "headline": "Software Engineer",
    "years_of_experience": 4,
    "stage": "applied",
    "resume": {
      "id": "resume_002",
      "file_name": "bagas_pratama.pdf"
    },
    "profile": {
      "skills": ["Dart", "Flutter", "Firebase", "Node.js"],
      "summary": "4 tahun di mobile dan backend ringan, kuat di delivery speed tapi pengalaman infra terbatas."
    }
  }'

put_json \
  "job:job_backend_001:candidate:cand_003" \
  '{
    "id": "cand_003",
    "job_id": "job_backend_001",
    "name": "Dewi Lestari",
    "headline": "Senior Backend Engineer",
    "years_of_experience": 7,
    "stage": "shortlisted",
    "resume": {
      "id": "resume_003",
      "file_name": "dewi_lestari.pdf"
    },
    "profile": {
      "skills": ["Go", "Kafka", "Redis", "Kubernetes", "SQL"],
      "summary": "7 tahun membangun backend skala tinggi, observability, dan incident handling."
    }
  }'

put_json \
  "job:job_backend_001:candidate:cand_004" \
  '{
    "id": "cand_004",
    "job_id": "job_backend_001",
    "name": "Arif Hidayat",
    "headline": "Backend Developer",
    "years_of_experience": 3,
    "stage": "applied",
    "resume": {
      "id": "resume_004",
      "file_name": "arif_hidayat.pdf"
    },
    "profile": {
      "skills": ["PHP", "Laravel", "MySQL"],
      "summary": "3 tahun membangun backend CRUD untuk sistem operasional dan admin dashboard."
    }
  }'

put_json \
  "job:job_backend_001:shortlist:latest" \
  '{
    "screening_id": "screen_001",
    "job_id": "job_backend_001",
    "status": "completed",
    "summary": "Top 3 kandidat dipilih dari 4 pelamar berdasarkan relevansi backend, pengalaman, dan risiko teknis.",
    "top_candidates": [
      {
        "candidate_id": "cand_003",
        "candidate_name": "Dewi Lestari",
        "rank": 1,
        "total_score": 91,
        "score_breakdown": {
          "skill_match": 34,
          "relevant_experience": 24,
          "domain_fit": 14,
          "communication_clarity": 9,
          "growth_potential": 10,
          "penalty": 0
        },
        "strengths": ["Go dan distributed systems kuat", "Pengalaman incident handling", "Scope senior"],
        "gaps": ["Perlu validasi ekspektasi kompensasi"],
        "red_flags": [],
        "recommendation": "shortlist",
        "rationale": "Paling relevan untuk backend production dengan kebutuhan reliability dan scale."
      },
      {
        "candidate_id": "cand_001",
        "candidate_name": "Rina Putri",
        "rank": 2,
        "total_score": 87,
        "score_breakdown": {
          "skill_match": 32,
          "relevant_experience": 22,
          "domain_fit": 14,
          "communication_clarity": 9,
          "growth_potential": 10,
          "penalty": 0
        },
        "strengths": ["API dan mentoring", "Stack relevan", "Komunikasi profile jelas"],
        "gaps": ["Belum terlihat pengalaman event streaming yang dalam"],
        "red_flags": [],
        "recommendation": "shortlist",
        "rationale": "Kandidat kuat untuk backend product dengan risiko onboarding rendah."
      },
      {
        "candidate_id": "cand_002",
        "candidate_name": "Bagas Pratama",
        "rank": 3,
        "total_score": 71,
        "score_breakdown": {
          "skill_match": 22,
          "relevant_experience": 19,
          "domain_fit": 10,
          "communication_clarity": 9,
          "growth_potential": 9,
          "penalty": 2
        },
        "strengths": ["Adaptif", "Dart/Node.js relevan sebagian", "Delivery cepat"],
        "gaps": ["Backend infra belum kuat", "Belum terlihat SQL dan observability mendalam"],
        "red_flags": ["Skill backend inti belum stabil"],
        "recommendation": "consider",
        "rationale": "Layak dipertimbangkan jika role lebih generalist, tapi belum sekuat dua kandidat teratas."
      }
    ]
  }'

put_json \
  "job:job_backend_001:screening:screen_001" \
  '{
    "id": "screen_001",
    "status": "completed"
  }'

put_json \
  "job:job_backend_001:screening:screen_001:summary" \
  '{
    "screening_id": "screen_001",
    "job_id": "job_backend_001",
    "status": "completed",
    "summary": "Top 3 kandidat dipilih dari 4 pelamar berdasarkan relevansi backend, pengalaman, dan risiko teknis.",
    "top_candidates": [
      {
        "candidate_id": "cand_003",
        "candidate_name": "Dewi Lestari",
        "rank": 1,
        "total_score": 91,
        "score_breakdown": {
          "skill_match": 34,
          "relevant_experience": 24,
          "domain_fit": 14,
          "communication_clarity": 9,
          "growth_potential": 10,
          "penalty": 0
        },
        "strengths": ["Go dan distributed systems kuat", "Pengalaman incident handling", "Scope senior"],
        "gaps": ["Perlu validasi ekspektasi kompensasi"],
        "red_flags": [],
        "recommendation": "shortlist",
        "rationale": "Paling relevan untuk backend production dengan kebutuhan reliability dan scale."
      },
      {
        "candidate_id": "cand_001",
        "candidate_name": "Rina Putri",
        "rank": 2,
        "total_score": 87,
        "score_breakdown": {
          "skill_match": 32,
          "relevant_experience": 22,
          "domain_fit": 14,
          "communication_clarity": 9,
          "growth_potential": 10,
          "penalty": 0
        },
        "strengths": ["API dan mentoring", "Stack relevan", "Komunikasi profile jelas"],
        "gaps": ["Belum terlihat pengalaman event streaming yang dalam"],
        "red_flags": [],
        "recommendation": "shortlist",
        "rationale": "Kandidat kuat untuk backend product dengan risiko onboarding rendah."
      },
      {
        "candidate_id": "cand_002",
        "candidate_name": "Bagas Pratama",
        "rank": 3,
        "total_score": 71,
        "score_breakdown": {
          "skill_match": 22,
          "relevant_experience": 19,
          "domain_fit": 10,
          "communication_clarity": 9,
          "growth_potential": 9,
          "penalty": 2
        },
        "strengths": ["Adaptif", "Dart/Node.js relevan sebagian", "Delivery cepat"],
        "gaps": ["Backend infra belum kuat", "Belum terlihat SQL dan observability mendalam"],
        "red_flags": ["Skill backend inti belum stabil"],
        "recommendation": "consider",
        "rationale": "Layak dipertimbangkan jika role lebih generalist, tapi belum sekuat dua kandidat teratas."
      }
    ]
  }'

echo "Seed completed."
echo "Job key: job:job_backend_001"
echo "Shortlist key: job:job_backend_001:shortlist:latest"
