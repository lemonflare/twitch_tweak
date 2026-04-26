#!/bin/sh

# GitHub 저장소 초기화 스크립트

echo "🚀 GitHub 저장소 초기화..."

# Git 초기화
if [ ! -d ".git" ]; then
    git init
    echo "✅ Git 저장소 초기화 완료"
else
    echo "⚠️  이미 Git 저장소가 있습니다"
fi

# 첫 커밋 생성
git add .
git commit -m "Initial commit: TwitchProxy iOS Tweak

- Add Theos build configuration
- Add iOS dylib tweak (Tweak.x)
- Add build script and GitHub Actions workflow
- Add README and LICENSE
- Based on ReYohoho Twitch Proxy userscript"

echo ""
echo "📋 다음 단계:"
echo ""
echo "1. GitHub에서 새 저장소 생성:"
echo "   https://github.com/new"
echo ""
echo "2. 리모트 추가:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
echo ""
echo "3. 푸시:"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "4. GitHub Actions 활성화:"
echo "   - Repository 페이지에서 Actions 탭 클릭"
echo "   - 'I understand my workflows, go ahead and enable them' 클릭"
echo ""
echo "5. 워크플로우 수동 실행 (선택):"
echo "   - Actions 탭 → 'Build TwitchProxy iOS' → 'Run workflow'"
echo ""
echo "✅ 완료! .deb 파일은 Releases 페이지에서 다운로드 가능합니다"
