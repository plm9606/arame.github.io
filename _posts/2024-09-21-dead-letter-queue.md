---
title: Dead Letter Queue
categories: [concepts]
tags: [queue]
author: aram
toc: true
comment: true
---
# DLQ

소프트웨어 시스템에서 오류로 인해 처리할 수 없는 메시지를 임시로 저장하는 특수한 유형의 메시지 대기열
대상이 없거나 의도한 수신자가 처리할 수 없는 잘못된 메시지를 저장한다

중요한 이유
DLQ는 잘못된 메시지 및 실패한 메시지의 임시 저장소 역할을 한다. DLQ는 소스 대기열에 처리되지 않은 메시지가 넘치지 않도록 한다.

> dlq로 이동하는 와중에 유실되는 경우는 없는지? dlq로 이동이 실패했을 때 일반 대기열에서 처리하는 방법?
> kafka와 dlq

장점
- 통신 비용 절감
    시스템에서 수천 개의 메세지를 처리하는 경우 메세지가 많으면 통신 오버헤드 비용이 증가. 실패한 메세지가 만료될 때 까지 해당 메세지를 처리하는 대신 몇번의 처리 시도 후 해당 메세지를 dlq로 이동하는것이 좋음
- 잘못된 메세지를 dql로 옮기면 개발자가 오류 원인을 식별하는데 집중할 수 있음. 디버깅이 쉬울 수도 있고.

단점
- 

tradeoff
언제 사용해야 할까?
- 메세지 순서가 중요하지 않은 경우 
- 메세지 순서가 중요한 경우 dlq도 fifo로 구현해야함

메시지 전송을 무한으로 재시도하려는 경우 정렬되지 않은 대기열과 함께 DLQ(Dead Letter Queue)를 사용해서는 안 됩니다. 예를 들어, 프로그램이 종속 프로세스가 활성화되거나 사용 가능해질 때까지 기다려야 하는 경우에는 DLQ(Dead Letter Queue)를 사용하지 않습니다. 

마찬가지로, 메시지 또는 작업의 정확한 순서를 그대로 유지하려면 선입선출(FIFO) 대기열과 함께 DLQ(Dead Letter Queue)를 사용해서는 안 됩니다. 예를 들어, 비디오 편집 제품군의 경우 편집 결정 목록(EDL)의 지침과 함께 DLQ(Dead Letter Queue)를 사용하지 않습니다. 이 경우 사용자가 편집 순서를 변경하여 후속 편집의 컨텍스트를 변경할 수 있습니다.


## 동작 방식



### ref
https://aws.amazon.com/ko/what-is/dead-letter-queue/
https://www.confluent.io/blog/kafka-connect-deep-dive-error-handling-dead-letter-queues/
